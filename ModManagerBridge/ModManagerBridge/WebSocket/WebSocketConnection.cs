using System;
using System.Text;
using System.Net.Sockets;
using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using ModManagerBridge.Models;
using ModManagerBridge.Service;
using ModManagerBridge.Core;
using System.Threading;

namespace ModManagerBridge.WebSocket
{
    /// <summary>
    /// 处理WebSocket连接
    /// </summary>
    public class WebSocketConnection
    {
        private TcpClient tcpClient;
        private NetworkStream stream;
        private ModManagerBridgeCore modCore;
        private bool isConnected = true;
        private int requestsInWindow = 0;
        private DateTime requestWindowStart = DateTime.UtcNow;

        public WebSocketConnection(TcpClient client, ModManagerBridgeCore modCore)
        {
            this.tcpClient = client;
            this.stream = client.GetStream();
            this.modCore = modCore;
        }

        public void HandleClient()
        {
            try
            {
                // 执行WebSocket握手
                if (!PerformHandshake())
                {
                    Close();
                    return;
                }

                // 处理消息（按帧精确读取）
                while (isConnected && tcpClient.Connected)
                {
                    int b0 = stream.ReadByte();
                    if (b0 < 0) break;
                    int b1 = stream.ReadByte();
                    if (b1 < 0) break;

                    byte opcode = (byte)(b0 & 0x0F);
                    bool rsv1 = (b0 & 0x40) != 0;
                    bool isMasked = (b1 & 0x80) != 0;
                    int payloadLen = b1 & 0x7F;

                    if (payloadLen == 126)
                    {
                        int hi = stream.ReadByte();
                        int lo = stream.ReadByte();
                        if (hi < 0 || lo < 0) break;
                        payloadLen = (hi << 8) | lo;
                    }
                    else if (payloadLen == 127)
                    {
                        byte[] lenBytes = new byte[8];
                        int read = stream.Read(lenBytes, 0, 8);
                        if (read < 8) break;
                        ulong ulen = BitConverter.ToUInt64(new byte[] { lenBytes[7], lenBytes[6], lenBytes[5], lenBytes[4], lenBytes[3], lenBytes[2], lenBytes[1], lenBytes[0] }, 0);
                        if (ulen > int.MaxValue) continue;
                        payloadLen = (int)ulen;
                    }

                    byte[] mask = null;
                    if (isMasked)
                    {
                        mask = new byte[4];
                        int mread = stream.Read(mask, 0, 4);
                        if (mread < 4) break;
                    }

                    byte[] payload = new byte[payloadLen];
                    int total = 0;
                    while (total < payloadLen)
                    {
                        int n = stream.Read(payload, total, payloadLen - total);
                        if (n <= 0) break;
                        total += n;
                    }
                    if (total < payloadLen) break;

                    if (isMasked)
                    {
                        for (int i = 0; i < payloadLen; i++)
                            payload[i] = (byte)(payload[i] ^ mask[i % 4]);
                    }

                    if (opcode == 0x09)
                    {
                        // Ping -> Pong
                        byte[] pong = new byte[payloadLen + (payloadLen < 126 ? 2 : (payloadLen < 65536 ? 4 : 10))];
                        int idx = 0;
                        pong[idx++] = 0x8A; // FIN + Pong
                        if (payloadLen < 126)
                        {
                            pong[idx++] = (byte)payloadLen;
                        }
                        else if (payloadLen < 65536)
                        {
                            pong[idx++] = 126;
                            pong[idx++] = (byte)((payloadLen >> 8) & 0xFF);
                            pong[idx++] = (byte)(payloadLen & 0xFF);
                        }
                        else
                        {
                            pong[idx++] = 127;
                            int len = payloadLen;
                            for (int i = 0; i < 8; i++) { pong[9 - i] = (byte)(len & 0xFF); len >>= 8; }
                            idx = 10;
                        }
                        Array.Copy(payload, 0, pong, idx, payloadLen);
                        stream.Write(pong, 0, pong.Length);
                        stream.Flush();
                        continue;
                    }

                    if (opcode != 0x01) continue;

                    string message;
                    if ((b0 & 0x40) != 0)
                    {
                        try
                        {
                            using (var input = new MemoryStream())
                            {
                                input.Write(payload, 0, payloadLen);
                                input.Write(new byte[] { 0x00, 0x00, 0xFF, 0xFF }, 0, 4);
                                input.Position = 0;
                                using (var deflate = new DeflateStream(input, CompressionMode.Decompress))
                                using (var output = new MemoryStream())
                                {
                                    deflate.CopyTo(output);
                                    message = Encoding.UTF8.GetString(output.ToArray());
                                }
                            }
                        }
                        catch { continue; }
                    }
                    else
                    {
                        message = Encoding.UTF8.GetString(payload);
                    }

                    if (!string.IsNullOrEmpty(message))
                    {
                        HandleWebSocketRequest(message);
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.LogError($"WebSocket连接错误: {ex.Message}");
            }
            finally
            {
                Close();
            }
        }

        private void HandleWebSocketRequest(string request)
        {
            try
            {
                Debug.Log($"收到WebSocket请求: {request}");
                var now = DateTime.UtcNow;
                if ((now - requestWindowStart).TotalSeconds >= 1.0)
                {
                    requestWindowStart = now;
                    requestsInWindow = 0;
                }
                int limit = modCore != null ? modCore.GetRequestsPerSecond() : 20;
                if (requestsInWindow >= limit)
                {
                    Send(JsonUtility.ToJson(new WebSocketResponse { success = false, message = "rate_limit_exceeded: requests_per_second" }));
                    return;
                }
                requestsInWindow++;
                
                // 检查请求是否为空
                if (string.IsNullOrEmpty(request))
                {
                    // 不记录错误，只是忽略空请求
                    return;
                }
                
                // 解析请求
                var requestData = JsonUtility.FromJson<WebSocketRequest>(request);
                
                string response = ProcessRequest(requestData);
                
                Send(response);
            }
            catch (Exception ex)
            {
                Debug.LogError($"处理WebSocket请求时出错: {ex.Message}");
                Send(JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "处理请求时出错: " + ex.Message 
                }));
            }
        }

        private string ProcessRequest(WebSocketRequest request)
        {
            // 将请求转发给处理模块
            var requestHandler = new ModRequestHandler(modCore);
            return requestHandler.ProcessRequest(request);
        }

        private bool PerformHandshake()
        {
            try
            {
                var sb = new StringBuilder();
                byte[] buffer = new byte[4096];
                while (true)
                {
                    int bytesRead = stream.Read(buffer, 0, buffer.Length);
                    if (bytesRead <= 0) break;
                    sb.Append(Encoding.UTF8.GetString(buffer, 0, bytesRead));
                    string current = sb.ToString();
                    if (current.Contains("\r\n\r\n")) break;
                    if (sb.Length > 65536)
                    {
                        Debug.LogError("握手失败，请求头过长");
                        return false;
                    }
                }

                string request = sb.ToString();
                Debug.Log($"握手请求原文:\n{request}");

                string webSocketKey = "";
                string version = "";
                bool upgradeOk = false;
                bool connectionUpgrade = false;

                string[] lines = request.Split(new[] { "\r\n" }, StringSplitOptions.None);
                foreach (string line in lines)
                {
                    int idx = line.IndexOf(':');
                    if (idx <= 0) continue;
                    string name = line.Substring(0, idx).Trim().ToLowerInvariant();
                    string value = line.Substring(idx + 1).Trim();
                    if (name == "sec-websocket-key") webSocketKey = value;
                    else if (name == "sec-websocket-version") version = value;
                    else if (name == "upgrade") upgradeOk = value.Equals("websocket", StringComparison.OrdinalIgnoreCase);
                    else if (name == "connection") connectionUpgrade = value.IndexOf("upgrade", StringComparison.OrdinalIgnoreCase) >= 0;
                }

                if (string.IsNullOrEmpty(webSocketKey))
                {
                    Debug.LogWarning("握手缺少 Sec-WebSocket-Key，按兼容模式继续");
                    webSocketKey = Convert.ToBase64String(Guid.NewGuid().ToByteArray());
                }
                if (!upgradeOk || !connectionUpgrade)
                {
                    Debug.LogWarning("握手警告，Upgrade/Connection 头异常");
                }
                if (!string.IsNullOrEmpty(version) && version != "13")
                {
                    Debug.LogWarning($"握手版本非13: {version}");
                }

                string responseKey = Convert.ToBase64String(
                    System.Security.Cryptography.SHA1.Create().ComputeHash(
                        Encoding.UTF8.GetBytes(webSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
                    )
                );

                string response = "HTTP/1.1 101 Switching Protocols\r\n" +
                                  "Upgrade: websocket\r\n" +
                                  "Connection: Upgrade\r\n" +
                                  "Sec-WebSocket-Accept: " + responseKey + "\r\n" +
                                  "\r\n";

                byte[] responseBytes = Encoding.UTF8.GetBytes(response);
                stream.Write(responseBytes, 0, responseBytes.Length);
                stream.Flush();

                return true;
            }
            catch (Exception ex)
            {
                Debug.LogError($"WebSocket握手错误: {ex.Message}");
                return false;
            }
        }

        private string DecodeWebSocketFrame(byte[] buffer, int length)
        {
            try
            {
                byte opcode = (byte)(buffer[0] & 0x0F);
                bool isMasked = (buffer[1] & 0x80) != 0;
                bool rsv1 = (buffer[0] & 0x40) != 0;
                
                if (opcode != 0x01)
                    return null;

                if (!isMasked)
                    return null;

                int payloadLength = buffer[1] & 0x7F;
                int payloadOffset = 6;
                
                if (payloadLength == 126)
                {
                    payloadLength = BitConverter.ToUInt16(new byte[] { buffer[3], buffer[2] }, 0);
                    payloadOffset = 8;
                }
                else if (payloadLength == 127)
                {
                    payloadLength = (int)BitConverter.ToUInt64(new byte[] { 
                        buffer[9], buffer[8], buffer[7], buffer[6], 
                        buffer[5], buffer[4], buffer[3], buffer[2] }, 0);
                    payloadOffset = 14;
                }

                byte[] mask = new byte[4];
                Array.Copy(buffer, payloadOffset - 4, mask, 0, 4);

                byte[] payload = new byte[payloadLength];
                Array.Copy(buffer, payloadOffset, payload, 0, payloadLength);

                for (int i = 0; i < payloadLength; i++)
                {
                    payload[i] = (byte)(payload[i] ^ mask[i % 4]);
                }

                if (rsv1)
                {
                    try
                    {
                        using (var input = new MemoryStream())
                        {
                            input.Write(payload, 0, payloadLength);
                            input.Write(new byte[] { 0x00, 0x00, 0xFF, 0xFF }, 0, 4);
                            input.Position = 0;
                            using (var deflate = new DeflateStream(input, CompressionMode.Decompress))
                            using (var output = new MemoryStream())
                            {
                                deflate.CopyTo(output);
                                return Encoding.UTF8.GetString(output.ToArray());
                            }
                        }
                    }
                    catch
                    {
                        return null;
                    }
                }

                return Encoding.UTF8.GetString(payload);
            }
            catch (Exception ex)
            {
                Debug.LogError($"解码WebSocket帧时出错: {ex.Message}");
                return null;
            }
        }

        public void Send(string message)
        {
            try
            {
                byte[] messageBytes = Encoding.UTF8.GetBytes(message);
                byte[] frame = EncodeWebSocketFrame(messageBytes);
                stream.Write(frame, 0, frame.Length);
                stream.Flush();
            }
            catch (Exception ex)
            {
                Debug.LogError($"发送WebSocket消息时出错: {ex.Message}");
                isConnected = false;
            }
        }

        private byte[] EncodeWebSocketFrame(byte[] message)
        {
            byte[] frame = new byte[message.Length + 10];
            frame[0] = 0x81; // FIN + text frame

            int payloadOffset;
            if (message.Length < 126)
            {
                frame[1] = (byte)message.Length;
                payloadOffset = 2;
            }
            else if (message.Length < 65536)
            {
                frame[1] = 126;
                frame[2] = (byte)((message.Length >> 8) & 0xFF);
                frame[3] = (byte)(message.Length & 0xFF);
                payloadOffset = 4;
            }
            else
            {
                frame[1] = 127;
                int len = message.Length;
                for (int i = 0; i < 8; i++)
                {
                    frame[9 - i] = (byte)(len & 0xFF);
                    len >>= 8;
                }
                payloadOffset = 10;
            }

            Array.Copy(message, 0, frame, payloadOffset, message.Length);
            byte[] result = new byte[message.Length + payloadOffset];
            Array.Copy(frame, result, result.Length);
            
            return result;
        }

        public void Close()
        {
            isConnected = false;
            
            if (stream != null)
            {
                stream.Close();
                stream = null;
            }
            
            if (tcpClient != null)
            {
                tcpClient.Close();
                tcpClient = null;
            }
        }
    }
}