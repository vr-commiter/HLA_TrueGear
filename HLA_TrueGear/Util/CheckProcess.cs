using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using Microsoft.Win32;
using System.Collections;
using System.Threading;
using MyTrueGear;

namespace HLA_TrueGear.Util
{
    internal class CheckProcess
    {
        
        public static void CheckAllIntegrity()
        {
            string directoryPath = GetSteamInstallPath();
            Console.WriteLine(directoryPath);
            Console.WriteLine("-------------------");
            directoryPath += @"\userdata\";
            Console.WriteLine(directoryPath);

            // 检查目录是否存在
            if (!Directory.Exists(directoryPath))
            {
                MessageBox.Show("请在steam启动选项中手动输入“-condebug”");
                Console.WriteLine($"目录不存在: {directoryPath}");
                return;
            }

            // 获取目录下的所有子文件夹
            string[] subdirectoryEntries = Directory.GetDirectories(directoryPath);
            Dictionary<string, string> keyNamePairs = new Dictionary<string, string>();
            bool canReload = false;
            foreach (string subdirectory in subdirectoryEntries)
            {
                DirectoryInfo dirInfo = new DirectoryInfo(subdirectory);
                if (dirInfo.Exists)
                {
                    string tempFilePath = directoryPath + $@"{dirInfo.Name}\config\localconfig.vdf";
                    string tempDirectoryPath = tempFilePath.Replace("\\localconfig.vdf", "");
                    if (!Directory.Exists(tempDirectoryPath))
                    {
                        Directory.CreateDirectory(tempDirectoryPath);
                    }
                    if (!File.Exists(tempFilePath))
                    {
                        using (FileStream fileStream = new FileStream(tempFilePath, FileMode.Create));
                    }
                    Console.WriteLine($"temp :{tempFilePath}");
                    if (!CheckSingleIntegrity(tempFilePath))
                    {
                        keyNamePairs.Add(dirInfo.Name, tempFilePath);
                        canReload = true;
                    }
                }
            }
            if (canReload)
            {
                bool isRunning = CheckProcess.IsProcessRunning("steam");
                if (isRunning)
                {
                    DialogResult result = MessageBox.Show("      您的游戏环境缺少重要文件，需重启steam\n\n                （点击【否】自行查看教程）", "环境缺失",MessageBoxButtons.YesNo);
                    if (result == DialogResult.Yes)
                    {
                        bool isClosed = CheckProcess.CloseApplicationAndWait("steam");
                        Thread.Sleep(1000);
                        if (isClosed)
                        {
                            Thread.Sleep(1500);
                            foreach (KeyValuePair<string, string> keyNamePair in keyNamePairs)
                            {
                                ChangeContent(keyNamePair.Value);
                                Thread.Sleep(10);
                            }
                            Thread.Sleep(500);
                            Form1.StartGame();
                        }
                        else
                        {
                            MessageBox.Show("应用程序未关闭或未找到\n          请手动修改");
                        }
                    }
                }
                else
                {
                    foreach (KeyValuePair<string, string> keyNamePair in keyNamePairs)
                    {
                        ChangeContent(keyNamePair.Value);
                    }
                }
            }
            else
            {
                Form1.StartGame();
            }
        }

        

        public static string GetSteamInstallPath()
        {
            const string keyPath = @"SOFTWARE\Valve\Steam";
            using (RegistryKey key = Registry.LocalMachine.OpenSubKey(keyPath))
            {
                if (key != null)
                {
                    object installPath = key.GetValue("InstallPath");
                    if (installPath != null)
                    {
                        return installPath.ToString();
                    }
                }
            }
            return null;
        }

        public static bool CheckSingleIntegrity(string filePath)
        {
            if (File.Exists(filePath))
            {
                var content = File.ReadAllText(filePath);
                bool configExists = InsertFile.CheckConfig(content, Form1.steamAppID, Form1.optionKey, Form1.optionValue);
                if (!configExists)
                {
                    return false;
                }
            }            
            return true;
        }

        public static void ChangeContent(string filePath)
        {
            if (File.Exists(filePath))
            {
                var content = File.ReadAllText(filePath);
                string fileContent = InsertFile.EnsureConfig(content, Form1.steamAppID, Form1.optionKey, Form1.optionValue);
                File.WriteAllText(filePath, fileContent);
            }
        }


        public static bool IsProcessRunning(string processName)
        {
            // 获取所有与指定名称匹配的进程
            Process[] processes = Process.GetProcessesByName(processName);
            return processes.Length > 0; // 如果有一个或多个进程正在运行，则返回 true
        }

        public static bool CloseApplicationAndWait(string processName)
        {
            foreach (var process in Process.GetProcessesByName(processName))
            {
                try
                {
                    process.Kill();
                    process.WaitForExit(); // 等待进程退出
                    return true; // 进程已成功关闭
                }
                catch (Exception ex)
                {
                    // 处理异常（例如，没有足够的权限关闭进程）
                    Console.WriteLine($"无法关闭进程 {processName}: {ex.Message}");
                }
            }
            return false; // 没有找到或无法关闭进程
        }


    }
}
