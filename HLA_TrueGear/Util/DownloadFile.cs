using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace HLA_TrueGear.Util
{
    internal class DownloadFile
    {
        public static async Task Download(string fileUrl, string relativePath)
        {
            // 提取URL中的文件名
            string fileName = Path.GetFileName(new Uri(fileUrl).AbsolutePath);
            string savePath = Path.Combine(relativePath, fileName);

            // 确保目录存在
            Directory.CreateDirectory(Path.GetDirectoryName(savePath));

            using (HttpClient client = new HttpClient())
            {
                HttpResponseMessage response = await client.GetAsync(fileUrl);
                if (response.IsSuccessStatusCode)
                {
                    using (var fileStream = new FileStream(savePath, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        await response.Content.CopyToAsync(fileStream);
                    }
                    MessageBox.Show("文件下载完成");
                }
                else
                {
                    MessageBox.Show("下载失败: " + response.StatusCode);
                }
            }
        }



    }
}
