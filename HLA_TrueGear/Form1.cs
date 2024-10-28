using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using HLA_TrueGear.Util;
using Microsoft.Win32;
using MyTrueGear;



namespace HLA_TrueGear
{
    public partial class Form1 : Form
    {
        //private string logFolderPath = Path.Combine(Application.StartupPath, "log"); // 日志文件夹的路径
        //private string logFilePath;
        //private StreamWriter logStreamWriter;

        public static string steamAppID = "546560";       //游戏ID
        public static string InertFilePath = "HLA_TrueGear.HLA_TrueGear.lua";
        public static string InertFileToPath = "\\game\\hlvr\\scripts\\vscripts\\HLA_TrueGear.lua";
        public static string InertContent = "script_reload_code HLA_TrueGear.lua";
        public static string InertContentToPath = "\\game\\hlvr\\cfg\\skill_manifest.cfg";
        public static string fileUrl = "https://huanglvyuantest1.oss-rg-china-mainland.aliyuncs.com/HLA_TrueGear.lua?Expires=1701163784&OSSAccessKeyId=TMP.3KeeKnJQZBp9XAPQixVdbDNGrd9QTEkbhixrTTBPS8BE5gaAshpKtHg83Qsbd3sgFcQ7yZ5CQSW5Ni4egzV5xSBgCHeZPS&Signature=mjkMNIAXRlnveRlxz1gkLIXjOgA%3D"; // 替换为你的文件URL
        public static string savePath = "downloads/"; // 替换为你想保存文件的路径

        //public static string filePath = @"D:\steam\userdata\1556666\config\localconfig.vdf";
        public static string optionKey = "LaunchOptions";
        public static string optionValue = "-condebug";

        private static string _selectedPath = null;
        private static Thread runLogThread = null;
        private static bool threadOnce = true;
        private static bool first = true;
        private static int counter = 0;

        
        public static bool isPausedGame = true;
        public static int shockCount = 0;

        private static TrueGearMod _TrueGear = null;

        private static bool isLowHeartBeat = false;
        private static bool isMidHeartBeat = false;
        private static bool isFastHeartBeat = false;
        private static bool isLeftReviverHeartItem = false;
        private static bool isRightReviverHeartItem = false;
        private static bool isCough = false;
        public static bool isPlayerUseHealthStation = false;
        public static bool isOpening = false;
        public static bool isDeath = false;
        private static string _SteamExe;





        private void CheckFir_Click(object sender, EventArgs e)
        {
            CheckProcess.CheckAllIntegrity();
        }

        public Form1()
        {
            //当有两个程序运行的时候，关闭前一个程序，保留当前程序
            string currentProcessName = Process.GetCurrentProcess().ProcessName;
            Process[] processes = Process.GetProcessesByName(currentProcessName);
            if (processes.Length > 1)
            {
                if (processes[0].UserProcessorTime.TotalMilliseconds > processes[1].UserProcessorTime.TotalMilliseconds)
                {
                    processes[0].Kill();
                }
                else
                {
                    processes[1].Kill();
                }
            }



            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            this.WindowState = FormWindowState.Minimized;

            _SteamExe = SteamExePath();
            string lastUsedPath = Properties.Settings.Default.LastUsedPath;
            if (!string.IsNullOrEmpty(lastUsedPath))
            {
                CheckPath(lastUsedPath);
            }
            else
            {
                string appIDPath =  FindPath.FindSteamAppIDPatch(steamAppID);
                if (!CheckPath(appIDPath))
                {
                    label1.Text = "请选择路径游戏的根目录<SteamLibrary\\common\\Half-Life Alyx>";
                    Play.Enabled = false;
                }
            }
            Stop.Enabled = false;
            CheckProcess.CheckAllIntegrity();            
        }

        private void Form1_FormClosed(object sender, FormClosedEventArgs e)
        {
            if (runLogThread != null)
            {
                runLogThread.Abort();                
            }
            if (_TrueGear != null)
            {
                _TrueGear.StopSDK();
                _TrueGear = null;
            }
        }

        private void folderBrowserDialog1_HelpRequest(object sender, EventArgs e)
        {

        }

        private bool CheckPath(string tmpSelectedPath)
        {
            string tmpProgramPath = tmpSelectedPath + "\\game\\bin\\win64\\";
            string tmpFilePath = Path.Combine(tmpProgramPath, "hlvr.exe");
            if (File.Exists(tmpFilePath))
            {
                _selectedPath = tmpSelectedPath;
                Console.WriteLine($"{_selectedPath}{InertFileToPath}");
                InsertFile.CreateFileFromResource(InertFilePath, $"{_selectedPath}{InertFileToPath}");
                InsertFile.CheckFileContent($"{_selectedPath}{InertContentToPath}", InertContent);
                label1.Text = _selectedPath;
                Properties.Settings.Default.LastUsedPath = _selectedPath;
                Properties.Settings.Default.Save();
                Play.Enabled = true;
                return true;
            }
            return false;
        }


        private void SelectPath_Click(object sender, EventArgs e)
        {
            if (folderBrowserDialog1.ShowDialog() == DialogResult.OK)
            {
                string tmpSelectedPath = folderBrowserDialog1.SelectedPath;
                if (!CheckPath(tmpSelectedPath))
                {
                    _selectedPath = null;
                    label1.Text = "请重新选择路径游戏的根目录<SteamLibrary\\common\\Half-Life Alyx>";
                    Properties.Settings.Default.LastUsedPath = _selectedPath;
                    Properties.Settings.Default.Save();
                    Play.Enabled = false;
                }
                
            }
        }
        public const string STEAM_OPENURL = "steam://rungameid/546560";
        public static string SteamExePath()
        {
            return (string)Registry.GetValue(@"HKEY_CURRENT_USER\SOFTWARE\Valve\Steam", "SteamExe", null);
        }
        private void Play_Click(object sender, EventArgs e)
        {
            if (threadOnce)
            {
                threadOnce = false;
                runLogThread = new Thread(runGetLog);
                runLogThread.Start();
                Play.Enabled = false;
                Stop.Enabled = true;
                SelectPath.Enabled = false;
                _TrueGear = new TrueGearMod();
                _TrueGear.Start();
            }
            else
            {
                MessageBox.Show("无需再次点击", "你已开始");
            }
            Thread.Sleep(500);
            if (_SteamExe != null)
                Process.Start(_SteamExe, STEAM_OPENURL);
        }

        public static void StartGame()
        {
           

            if (threadOnce)
            {
                threadOnce = false;
                runLogThread = new Thread(runGetLog);
                runLogThread.Start();
                Play.Enabled = false;
                Stop.Enabled = true;
                SelectPath.Enabled = false;
                _TrueGear = new TrueGearMod();
                _TrueGear.Start();
            }
            Thread.Sleep(500);
            if (_SteamExe != null)
                Process.Start(_SteamExe, STEAM_OPENURL);
        }

        private void Stop_Click(object sender, EventArgs e)
        {            
            DialogResult result = MessageBox.Show("确定停止?", "确认", MessageBoxButtons.YesNo);
            if (result == DialogResult.Yes)
            {
                runLogThread.Abort();
                _TrueGear.lowHeartBeatThred.Abort();
                _TrueGear.midHeartBeatThred.Abort();
                _TrueGear.fastHeartBeatThred.Abort();
                _TrueGear.leftreviverheartitemThred.Abort();
                _TrueGear.rightreviverheartitemThred.Abort();
                _TrueGear.coughThred.Abort();
                _TrueGear.playerusehealthstationThred.Abort();
                _TrueGear.playeropenhealthstationThred.Abort();
                first = true;
                threadOnce = true;
                counter = 0;
                Play.Enabled = true;
                Stop.Enabled = false;
                SelectPath.Enabled = true;
                _TrueGear = null;
                isLowHeartBeat = false;
                isMidHeartBeat = false;
                isFastHeartBeat = false;
                isLeftReviverHeartItem = false;
                isRightReviverHeartItem = false;
                isCough = false;
                isPlayerUseHealthStation = false;
                isOpening = false;
                MessageBox.Show("你已停止", "");
            }
        }

        private async void Download_Click(object sender, EventArgs e)
        {
            await DownloadFile.Download(fileUrl, savePath);
        }

        public static IEnumerable<string> ReadLines(string path)
        {
            using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite, 0x1000, FileOptions.SequentialScan))
            using (var sr = new StreamReader(fs, Encoding.UTF8))
            {
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    yield return line;
                }
            }
        }

        public static void runGetLog()
        {
            try
            {
                //if (!Directory.Exists(logFolderPath))
                //{
                //    Directory.CreateDirectory(logFolderPath);
                //}
                //DateTime currentTime = DateTime.Now;
                //string disTime = currentTime.Year.ToString() + currentTime.Month.ToString() + currentTime.Day.ToString() + currentTime.Hour.ToString() + currentTime.Minute.ToString() + currentTime.Second.ToString();
                //Console.WriteLine(disTime);
                //logFilePath = Path.Combine(logFolderPath, disTime + ".txt");
                //logStreamWriter = new StreamWriter(logFilePath, true);


                while (true)
                {
                    if (File.Exists($"{_selectedPath}\\game\\hlvr\\console.log"))
                    {
                        if (first)
                        {
                            first = false;
                            counter = ReadLines($"{_selectedPath}\\game\\hlvr\\console.log").Count();
                        }
                        int lineCount = ReadLines($"{_selectedPath}\\game\\hlvr\\console.log").Count();//read text file line count to establish length for array
                        if (counter < lineCount && lineCount > 0)//if counter is less than lineCount keep reading lines
                        {
                            var lines = Enumerable.ToList(ReadLines($"{_selectedPath}\\game\\hlvr\\console.log").Skip(counter).Take(lineCount - counter));
                            for (int i = 0; i < lines.Count; i++)//读出了新插入的log条数
                            {
                                if (lines[i].Contains("rueGear]"))
                                {
                                    string line = lines[i].Substring(lines[i].LastIndexOf(':') + 1);
                                    string trimmedInput = line.Trim('{', '}');

                                    //Console.WriteLine(trimmedInput);
                                    GameEventCheck(trimmedInput);

                                }
                                else if (lines[i].Contains("[Client]"))
                                {
                                    if (lines[i].Contains("unpaused the game"))
                                    {
                                        if(isLowHeartBeat) _TrueGear.StartLowHeartBeat();
                                        if(isMidHeartBeat) _TrueGear.StartMidHeartBeat();
                                        if(isFastHeartBeat) _TrueGear.StartFastHeartBeat();
                                        if(isCough) _TrueGear.StartPlayerCough();
                                        if(isLeftReviverHeartItem) _TrueGear.StartLeftReviverHeartItem();
                                        if(isRightReviverHeartItem) _TrueGear.StartRightReviverHeartItem();
                                        if(isPlayerUseHealthStation) _TrueGear.StartPlayerUseHealthStation(_TrueGear.shockCountAgain);
                                        if(isOpening) _TrueGear.StartPlayerOpenHealthStation();
                                    }
                                    else if (lines[i].Contains("paused the game"))
                                    {
                                        _TrueGear.StopLowHeartBeat();
                                        _TrueGear.StopMidHeartBeat();
                                        _TrueGear.StopFastHeartBeat();
                                        _TrueGear.StopPlayerCough();
                                        _TrueGear.StopLeftReviverHeartItem();
                                        _TrueGear.StopRightReviverHeartItem();
                                        _TrueGear.StopPlayerUseHealthStation();
                                        _TrueGear.StopPlayerOpenHealthStation();
                                    }
                                }
                                else if (lines[i].Contains("[Server]") && lines[i].Contains("Game started"))
                                {
                                    Console.WriteLine("Start Game");
                                    isDeath = false;
                                    _TrueGear.StopLowHeartBeat();
                                    _TrueGear.StopMidHeartBeat();
                                    _TrueGear.StopFastHeartBeat();
                                    _TrueGear.StopPlayerCough();
                                    _TrueGear.StopLeftReviverHeartItem();
                                    _TrueGear.StopRightReviverHeartItem();
                                    _TrueGear.StopPlayerUseHealthStation();
                                    isLowHeartBeat = false;
                                    isMidHeartBeat = false;
                                    isFastHeartBeat = false;
                                    isCough = false;
                                    isLeftReviverHeartItem = false;
                                    isRightReviverHeartItem=false;
                                    isPlayerUseHealthStation = false;
                                }
                            }
                            counter += lines.Count;
                        }
                        else if (counter == lineCount && lineCount > 0)//如果游戏没有新的log就休眠50ms
                        {
                            Thread.Sleep(50);
                        }
                        else
                        {
                            counter = 0;
                        }
                    }
                }
                //logStreamWriter.Close();
            }
            catch (Exception ex)
            {
                // 记录异常信息
                //Console.WriteLine("发生异常：" + ex.Message);
                //Console.WriteLine("堆栈跟踪：" + ex.StackTrace);

                //// 在日志文件中写入异常信息
                //if (logStreamWriter != null)
                //{
                //    logStreamWriter.WriteLine("发生异常：" + ex.Message);
                //    logStreamWriter.WriteLine("堆栈跟踪：" + ex.StackTrace);
                //}
            }            
        }

        private static void GameEventCheck(string gameEvent)
        {
            Console.WriteLine($"{gameEvent}");
            if (gameEvent.Contains("PlayerDeath"))
            {                
                _TrueGear.Play(gameEvent);
                Console.WriteLine($"{gameEvent}");
                _TrueGear.StopLowHeartBeat();
                _TrueGear.StopMidHeartBeat();
                _TrueGear.StopFastHeartBeat();
                _TrueGear.StopPlayerCough();
                _TrueGear.StopLeftReviverHeartItem();
                _TrueGear.StopRightReviverHeartItem();
                _TrueGear.StopPlayerUseHealthStation();
                isLowHeartBeat = false;
                isMidHeartBeat = false;
                isFastHeartBeat = false;
                isCough = false;
                isLeftReviverHeartItem = false;
                isRightReviverHeartItem = false;
                isPlayerUseHealthStation = false;
                isDeath = true;
            }
            else if (gameEvent.Contains("Damage") && !gameEvent.Contains("Barnacle"))
            {
                //Console.WriteLine("damage1111111");
                string[] damage = gameEvent.Split(',');
                _TrueGear.PlayAngle(damage[0], float.Parse(damage[1]), float.Parse(damage[2]));
            }
            else if (gameEvent.Contains("HealthStation"))
            {
                if (gameEvent.Contains("Open"))
                {
                    isOpening = true;
                    _TrueGear.StartPlayerOpenHealthStation();
                }
                else
                {
                    string[] shockCount = gameEvent.Split(',');
                    double doubleValue = 0;
                    int count = 0;
                    Console.WriteLine(shockCount[1]);
                    if (double.TryParse(shockCount[1], out doubleValue))
                    {
                        Console.WriteLine(doubleValue);
                        if (doubleValue != 0) doubleValue++;
                        count = (int)doubleValue;
                    }
                    Console.WriteLine(count);
                    _TrueGear.StartPlayerUseHealthStation(count);
                    isPlayerUseHealthStation = true;
                }
            }
            else if (gameEvent.Contains("Start") && !gameEvent.Contains("Link"))
            {
                if (gameEvent.Contains("LowHeartBeat"))
                {
                    _TrueGear.StartLowHeartBeat();
                    isLowHeartBeat = true;
                }
                else if (gameEvent.Contains("MidHeartBeat"))
                {
                    _TrueGear.StartMidHeartBeat();
                    isMidHeartBeat = true;
                }
                else if (gameEvent.Contains("FastHeartBeat"))
                {
                    _TrueGear.StartFastHeartBeat();
                    isFastHeartBeat = true;
                }
                else if (gameEvent.Contains("LeftReviverHeartItem"))
                {
                    _TrueGear.StartLeftReviverHeartItem();
                    isLeftReviverHeartItem = true;
                }
                else if (gameEvent.Contains("RightReviverHeartItem"))
                {
                    _TrueGear.StartRightReviverHeartItem();
                    isRightReviverHeartItem = true;
                }
                else if (gameEvent.Contains("PlayerCough"))
                {
                    _TrueGear.StartPlayerCough();
                    isCough = true;
                }
            }
            else if (gameEvent.Contains("Stop"))
            {
                if (gameEvent.Contains("LowHeartBeat"))
                {
                    _TrueGear.StopLowHeartBeat();
                    isLowHeartBeat = false;
                }
                else if (gameEvent.Contains("MidHeartBeat"))
                {
                    _TrueGear.StopMidHeartBeat();
                    isMidHeartBeat = false;
                }
                else if (gameEvent.Contains("FastHeartBeat"))
                {
                    _TrueGear.StopFastHeartBeat();
                    isFastHeartBeat = false;
                }
                else if (gameEvent.Contains("LeftReviverHeartItem"))
                {
                    _TrueGear.StopLeftReviverHeartItem();
                    isLeftReviverHeartItem = false;
                }
                else if (gameEvent.Contains("RightReviverHeartItem"))
                {
                    _TrueGear.StopRightReviverHeartItem();
                    isRightReviverHeartItem = false;
                }
                else if (gameEvent.Contains("PlayerCough"))
                {
                    _TrueGear.StopPlayerCough();
                    isCough = false;
                }
            }
            else
            {
                _TrueGear.Play(gameEvent);
            }
        }




        
    }
}
