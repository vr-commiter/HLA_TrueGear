using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection.Emit;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace HLA_TrueGear
{
    internal class FindPath
    {
        public static string FindSteamAppIDPatch(string appID)
        {
            string steamPath = FindPath.GetSteamPath();
            if (steamPath != null)
            {
                string gamePath = FindPath.GetGamePath(steamPath, appID);
                return gamePath;
            }
            else
            {
                MessageBox.Show("出了点问题", "请手动选择路径");
            }
            return null;
        }


        public static string GetSteamPath()
        {
            using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\WOW6432Node\Valve\Steam"))
            {
                if (key != null)
                {
                    return key.GetValue("InstallPath") as string;
                }
            }
            return null;
        }

        public static string GetGamePath(string steamPath, string appId)
        {
            string libraryFoldersPath = Path.Combine(steamPath, "steamapps", "libraryfolders.vdf");
            List<string> libraryFolders = ParseVdf(libraryFoldersPath);

            string gamePath = FindGamePath(libraryFolders, appId);

            if (gamePath != null)
            {
                gamePath = gamePath.Replace("/", @"\");
                gamePath = gamePath.Replace(@"\\", @"\");
                return gamePath;
            }
            else
            {
                MessageBox.Show("未找到您的游戏路径", "请手动选择路径");
            }

            return null; // 返回游戏安装路径
        }

        public static string FindGamePath(List<string> libraryFolders, string appId)
        {
            foreach (var folder in libraryFolders)
            {
                string manifestPath = Path.Combine(folder, $"steamapps/appmanifest_{appId}.acf");
                if (File.Exists(manifestPath))
                {
                    string installDir = ParseInstallDir(manifestPath);
                    if (!string.IsNullOrEmpty(installDir))
                    {
                        return Path.Combine(folder, "steamapps/common/", installDir);
                    }
                }
            }

            return null;
        }

        public static string ParseInstallDir(string manifestPath)
        {
            string fileContent = File.ReadAllText(manifestPath);
            var match = Regex.Match(fileContent, "\"installdir\"\\s*\"(.+?)\"");

            if (match.Success)
            {
                return match.Groups[1].Value;
            }

            return null;
        }

        public static List<string> ParseVdf(string filePath)
        {
            var libraryFolders = new List<string>();
            string fileContent = File.ReadAllText(filePath);

            var matches = Regex.Matches(fileContent, "\"path\"\\s*\"(.+?)\"");

            foreach (Match match in matches)
            {
                libraryFolders.Add(match.Groups[1].Value);
            }
            return libraryFolders;
        }




    }

}
