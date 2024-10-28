namespace HLA_TrueGear
{
    partial class Form1
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要修改
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            SelectPath = new System.Windows.Forms.Button();
            Play = new System.Windows.Forms.Button();
            folderBrowserDialog1 = new System.Windows.Forms.FolderBrowserDialog();
            label1 = new System.Windows.Forms.Label();
            Stop = new System.Windows.Forms.Button();
            CheckFir = new System.Windows.Forms.Button();
            SuspendLayout();
            // 
            // SelectPath
            // 
            SelectPath.Location = new System.Drawing.Point(475, 175);
            SelectPath.Name = "SelectPath";
            SelectPath.Size = new System.Drawing.Size(75, 23);
            SelectPath.TabIndex = 0;
            SelectPath.Text = "选择路径";
            SelectPath.UseVisualStyleBackColor = true;
            SelectPath.Click += new System.EventHandler(this.SelectPath_Click);
            // 
            // Play
            // 
            Play.Location = new System.Drawing.Point(245, 261);
            Play.Name = "Play";
            Play.Size = new System.Drawing.Size(75, 23);
            Play.TabIndex = 1;
            Play.Text = "开始";
            Play.UseVisualStyleBackColor = true;
            Play.Click += new System.EventHandler(this.Play_Click);
            // 
            // folderBrowserDialog1
            // 
            folderBrowserDialog1.HelpRequest += new System.EventHandler(this.folderBrowserDialog1_HelpRequest);
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Location = new System.Drawing.Point(191, 61);
            label1.Name = "label1";
            label1.Size = new System.Drawing.Size(41, 12);
            label1.TabIndex = 3;
            label1.Text = "label1";
            // 
            // Stop
            // 
            Stop.Location = new System.Drawing.Point(475, 261);
            Stop.Name = "Stop";
            Stop.Size = new System.Drawing.Size(75, 23);
            Stop.TabIndex = 5;
            Stop.Text = "停止";
            Stop.UseVisualStyleBackColor = true;
            Stop.Click += new System.EventHandler(this.Stop_Click);
            // 
            // CheckFir
            // 
            CheckFir.Location = new System.Drawing.Point(245, 175);
            CheckFir.Name = "CheckFir";
            CheckFir.Size = new System.Drawing.Size(75, 23);
            CheckFir.TabIndex = 7;
            CheckFir.Text = "检查第一次";
            CheckFir.UseVisualStyleBackColor = true;
            CheckFir.Click += new System.EventHandler(this.CheckFir_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 12F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 450);
            this.Controls.Add(CheckFir);
            this.Controls.Add(Stop);
            this.Controls.Add(label1);
            this.Controls.Add(Play);
            this.Controls.Add(SelectPath);
            this.Name = "Form1";
            this.Text = "HLA_TrueGear";
            this.FormClosed += new System.Windows.Forms.FormClosedEventHandler(this.Form1_FormClosed);
            this.Load += new System.EventHandler(this.Form1_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private static System.Windows.Forms.Button SelectPath;
        private static System.Windows.Forms.Button Play;
        private static System.Windows.Forms.FolderBrowserDialog folderBrowserDialog1;
        private static System.Windows.Forms.Label label1;
        private static System.Windows.Forms.Button Stop;
        private static System.Windows.Forms.Button CheckFir;
    }
}

