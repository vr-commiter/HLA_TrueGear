using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace HLA_TrueGear.Util
{
    internal class InsertFile
    {
        public static void CreateFileFromResource(string resourcePath, string outputPath)
        {
            string directoryPath = Path.GetDirectoryName(outputPath);
            if (!Directory.Exists(directoryPath))
            {
                Directory.CreateDirectory(directoryPath);
            }

            using (Stream resourceStream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourcePath))
            {
                if (resourceStream == null)
                {
                    throw new FileNotFoundException("请手动安装游戏mod");
                }

                using (FileStream fileStream = new FileStream(outputPath, FileMode.Create))
                {
                    resourceStream.CopyTo(fileStream);
                }
            }
        }

        public static void CheckFileContent(string filePath, string sentenceToFind)
        {
            try
            {
                string fileContent = File.ReadAllText(filePath);

                if (!fileContent.Contains(sentenceToFind))
                {
                    fileContent += "\n" + sentenceToFind;
                    File.WriteAllText(filePath, fileContent);
                }
            }
            catch (IOException e)
            {

            }
        }

        static string ExtractContentInBraces(string content, int startIndex)
        {
            if (startIndex == -1)
            {
                return null; // 如果找不到起始花括号，则返回 null
            }

            int endIndex = FindMatchingClosingBrace(content, startIndex);

            if (endIndex == -1)
            {
                return null; // 如果找不到匹配的结束花括号，则返回 null
            }

            // 将结束位置索引加 1，以包括结束花括号
            return content.Substring(startIndex + 1, endIndex - startIndex);
        }

        static int FindMatchingClosingBrace(string content, int startIndex)
        {
            int count = 0;
            for (int i = startIndex - 1; i < content.Length; i++)
            {
                if (content[i] == '{')
                {
                    count++;
                }
                else if (content[i] == '}')
                {
                    count--;
                    if (count == 0)
                    {
                        return i;
                    }
                }

                if (count < 0)
                {

                    Console.WriteLine("小于0");
                    // 如果计数小于零，说明起始花括号和结束花括号不匹配，直接返回 -1
                    return -1;
                }

            }

            Console.WriteLine("没招到");
            return -1; // 没有找到匹配的结束花括号
        }


        public static bool CheckConfig(string content, string appId, string optionKey, string optionValue)
        {
            string appsPattern = "\"apps\"";
            string appIdPattern = $"\"{appId}\"";
            string optionKeyWithValuePattern = $"\"{optionKey}\"\t\t\"{optionValue}\""; // 两个制表符间隔
            // 定位到"apps"的位置
            int appsIndex = content.IndexOf(appsPattern);
            string appsIndexContent = ExtractContentInBraces(content, appsIndex);
            if (appsIndex != -1)
            {
                // 检查是否有appId
                int appIdIndex = appsIndexContent.IndexOf(appIdPattern);
                string appIdIndexContent = ExtractContentInBraces(appsIndexContent, appIdIndex);                
                if (appIdIndex != -1)
                {
                    // 检查appId下是否有正确的optionKey和optionValue
                    Console.WriteLine(appIdIndexContent.IndexOf(optionKeyWithValuePattern));
                    return appIdIndexContent.IndexOf(optionKeyWithValuePattern) != -1;
                }
            }
            return false;
        }

        public static string EnsureConfig(string content, string appId, string optionKey, string optionValue)
        {

            string startPattern = "\"UserLocalConfigStore\"";
            string softwarePattern = "\"Software\"";
            string valvePattern = "\"Valve\"";
            string steamPattern = "\"Steam\"";
            string appsPattern = "\"apps\"";
            string appIdPattern = $"\"{appId}\"";
            string optionKeyExistPattern = $"\"{optionKey}\"";
            string optionKeyWithValuePattern = $"\"{optionKey}\"\t\t\"{optionValue}\""; // 两个制表符间隔

            // 定位到"UserLocalConfigStore"开始的地方
            int startIndex = content.IndexOf(startPattern);
            
            if (startIndex == -1)
            {
                content = content.Insert(0, startPattern + "\n{\n}");
                startIndex = content.IndexOf(startPattern);
            }

            // 定位到"Software"的位置
            int softwareIndex = content.IndexOf(softwarePattern, startIndex);
            if (softwareIndex == -1)
            {
                int startBracketIndex = content.IndexOf('{', startIndex);
                content = content.Insert(startBracketIndex + 1, "\n\t" + softwarePattern + "\n\t{\n\t}");
                softwareIndex = content.IndexOf(softwarePattern, startIndex);
            }

            // 定位到"Valve"的位置
            int valveIndex = content.IndexOf(valvePattern, softwareIndex);
            if (valveIndex == -1)
            {
                int softwareBracketIndex = content.IndexOf('{', softwareIndex);
                content = content.Insert(softwareBracketIndex + 1, "\n\t\t" + valvePattern + "\n\t\t{\n\t\t}");
                valveIndex = content.IndexOf(valvePattern, softwareIndex);
            }

            // 定位到"Steam"的位置
            int steamIndex = content.IndexOf(steamPattern, valveIndex);
            if (steamIndex == -1)
            {
                int valveBracketIndex = content.IndexOf('{', valveIndex);
                content = content.Insert(valveBracketIndex + 1, "\n\t\t\t" + steamPattern + "\n\t\t\t{\n\t\t\t}");
                steamIndex = content.IndexOf(steamPattern, valveIndex);
            }

            // 定位到"apps"的位置
            int appsIndex = content.IndexOf(appsPattern, steamIndex);
            if (appsIndex == -1)
            {
                int steamBracketIndex = content.IndexOf('{', steamIndex);
                content = content.Insert(steamBracketIndex + 1, "\n\t\t\t\t" + appsPattern + "\n\t\t\t\t{\n\t\t\t\t}");
                appsIndex = content.IndexOf(appsPattern, steamIndex);
            }

            // 寻找"apps"后的第一个大括号位置
            int appsBracketIndex = content.IndexOf('{', appsIndex);
            if (appsBracketIndex != -1)
            {
                var appIdContent = ExtractContentInBraces(content, appsBracketIndex);
                // 检查是否有appId
                int appIdIndex = appIdContent.IndexOf(appIdPattern);
                //Console.WriteLine($"appIdContent :{appIdContent}");
                Console.WriteLine($"appindex :{appIdIndex}");
                if (appIdIndex == -1)
                {
                    // 在"apps"的大括号内插入appId及其相关数据
                    string toInsert = $"\n\t\t\t\t\t\"{appId}\"\n\t\t\t\t\t{{\n\t\t\t\t\t\t{optionKeyWithValuePattern}\n\t\t\t\t\t}}";
                    content = content.Insert(appsBracketIndex + 1, toInsert);
                }
                else
                {

                    int appIdIndexBracketIndex = appIdContent.IndexOf('{', appIdIndex);
                    int appIdIndexBracketAfterIndex = FindMatchingClosingBrace(appIdContent, appIdIndex);



                    var appIdContent111 = ExtractContentInBraces(appIdContent, appIdIndexBracketIndex);
                    Console.WriteLine($"appIdContent111 :{appIdContent111}");




                    // 检查是否有optionKey
                    int optionKeyIndex = appIdContent111.IndexOf(optionKeyExistPattern);
                    Console.WriteLine($"optionKeyIndex :{optionKeyIndex}");
                    if (optionKeyIndex == -1)
                    {
                        // 找到appId大括号的内部位置
                        int appIdBracketInnerIndex = appIdIndexBracketIndex + 1;
                        string toInsert = $"\n\t\t\t\t\t\t{optionKeyWithValuePattern}";
                        content = content.Insert(appIdBracketInnerIndex + appsBracketIndex + 1, toInsert);
                    }
                    else
                    {
                        // 更新optionKey的值（仅当当前值不正确时）
                        // 找到optionKey的结束位置并替换其值，确保格式与原始文件一致
                        int endOfOptionKey = appIdContent111.IndexOf('\n', optionKeyIndex);
                        content = content.Remove(optionKeyIndex + appsBracketIndex + 1, endOfOptionKey - optionKeyIndex);
                        content = content.Insert(optionKeyIndex + appsBracketIndex + 1, optionKeyWithValuePattern);
                    }
                }
            }

            return content;
        }

    }
}
