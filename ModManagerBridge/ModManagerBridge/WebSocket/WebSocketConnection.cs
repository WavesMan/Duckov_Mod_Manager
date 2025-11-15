using System;
using System.Text;
using System.Net.Sockets;
using UnityEngine;
using System.Collections.Generic;
using ModManagerBridge.Models;
using ModManagerBridge.Service;
using ModManagerBridge.Core;

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

                // 处理消息
                byte[] buffer = new byte[1024];
                while (isConnected && tcpClient.Connected)
                {
                    int bytesRead = stream.Read(buffer, 0, buffer.Length);
                    if (bytesRead > 0)
                    {
                        string message = DecodeWebSocketFrame(buffer, bytesRead);
                        // 检查消息是否为空或null
                        if (!string.IsNullOrEmpty(message))
                        {
                            // 这里需要处理请求
                            HandleWebSocketRequest(message);
                        }
                        // 如果消息为空，忽略它而不是尝试处理
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
            var requestHandler = new ModRequestHandler();
            return requestHandler.ProcessRequest(request);
        }

        private bool PerformHandshake()
        {
            try
            {
                byte[] buffer = new byte[1024];
                int bytesRead = stream.Read(buffer, 0, buffer.Length);
                string request = Encoding.UTF8.GetString(buffer, 0, bytesRead);

                string webSocketKey = "";
                string[] lines = request.Split(new[] { "\r\n" }, StringSplitOptions.None);
                foreach (string line in lines)
                {
                    if (line.StartsWith("Sec-WebSocket-Key:"))
                    {
                        webSocketKey = line.Substring(19).Trim();
                        break;
                    }
                }

                if (string.IsNullOrEmpty(webSocketKey))
                {
                    return false;
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
                
                // 如果不是文本帧，返回null
                if (opcode != 0x01) // 0x01是文本帧
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