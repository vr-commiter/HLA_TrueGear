using System.Collections.Generic;
using System.Threading;
using System.IO;
using System;
using TrueGearSDK;
using HLA_TrueGear;
using System.Linq;
using System.Windows.Forms;

namespace MyTrueGear
{
    public class TrueGearMod
    {
        public Thread lowHeartBeatThred = null;
        public Thread midHeartBeatThred = null;
        public Thread fastHeartBeatThred = null;
        public Thread leftreviverheartitemThred = null;
        public Thread rightreviverheartitemThred = null;
        public Thread coughThred = null;
        public Thread playerusehealthstationThred = null;
        public Thread playeropenhealthstationThred = null;

        public int shockCount = 0;

        private static TrueGearPlayer _player = null;

        private static ManualResetEvent lowheartbeatMRE = new ManualResetEvent(false);
        private static ManualResetEvent midheartbeatMRE = new ManualResetEvent(false);
        private static ManualResetEvent fastheartbeatMRE = new ManualResetEvent(false);
        private static ManualResetEvent leftreviverheartitemMRE = new ManualResetEvent(false);
        private static ManualResetEvent rightreviverheartitemMRE = new ManualResetEvent(false);
        private static ManualResetEvent coughMRE = new ManualResetEvent(false);
        private static ManualResetEvent playerusehealthstationMRE = new ManualResetEvent(false);
        private static ManualResetEvent playeropenhealthstationMRE = new ManualResetEvent(false);

        public int shockCountAgain = 0;
        private static int shockNum = 0;

        private int lowCount = 0;
        private int midCount = 0;
        private int fastCount = 0;


        public class RootObject
        {
            public string name { get; set; }
            public string uuid { get; set; }
            public string keep { get; set; }
            public List<Track> tracks { get; set; }
        }

        public class Track
        {
            public int start_time { get; set; }
            public int end_time { get; set; }
            public string stop_name { get; set; }
            public int start_intensity { get; set; }
            public int end_intensity { get; set; }
            public string intensity_mode { get; set; }
            public string action_type { get; set; }
            public string once { get; set; }
            public int interval { get; set; }
            public List<int> index { get; set; }
        }

        public void LowHeartBeat()
        {
            while(true)
            {
                lowheartbeatMRE.WaitOne();
                _player.SendPlay("LowHeartBeat");
                lowCount++;
                if (lowCount >= 37)
                { 
                    lowCount = 0;
                    StopLowHeartBeat();
                }
                Thread.Sleep(800);
            }            
        }

        public void MidHeartBeat()
        {
            while (true)
            {
                midheartbeatMRE.WaitOne();
                _player.SendPlay("MidHeartBeat");
                midCount++;
                if (midCount >= 46)
                {
                    midCount = 0;
                    StopMidHeartBeat();
                }
                Thread.Sleep(650);
            }
        }

        public void FastHeartBeat()
        {
            while (true)
            {
                fastheartbeatMRE.WaitOne();
                _player.SendPlay("FastHeartBeat");
                fastCount++;
                if (fastCount >= 60)
                {
                    fastCount = 0;
                    StopFastHeartBeat();
                }
                Thread.Sleep(500);
            }
        }

        public void LeftReviverHeartItem()
        {
            while (true)
            {
                leftreviverheartitemMRE.WaitOne();
                _player.SendPlay("LeftReviverHeartItem");
                Thread.Sleep(1200);
            }
        }

        public void RightReviverHeartItem()
        {
            while (true)
            {
                rightreviverheartitemMRE.WaitOne();
                _player.SendPlay("RightReviverHeartItem");
                Thread.Sleep(1200);
            }
        }

        public void PlayerCough()
        {
            while (true)
            {
                coughMRE.WaitOne();
                _player.SendPlay("PlayerCough");
                Thread.Sleep(1500);
            }
        }

        public void PlayerUseHealthStation()
        {
            while (true)
            {
                playerusehealthstationMRE.WaitOne();
                if (!Form1.isOpening)
                {                    
                    if (shockCount < shockNum)
                    {
                        shockCount++;
                        shockCountAgain = shockNum - shockCount;
                        _player.SendPlay("PlayerUseHealthStation");
                        Thread.Sleep(1800);
                    }
                    else
                    {
                        StopPlayerUseHealthStation();
                        Form1.isPlayerUseHealthStation = false;
                    }
                }               
            }
        }

        public void PlayerOpenHealthStation()
        {
            while (true)
            {
                playeropenhealthstationMRE.WaitOne();
                if (Form1.isOpening)
                {
                    Thread.Sleep(4000);
                    Form1.isOpening = false;
                    StopPlayerOpenHealthStation();
                }
            }
        }

        public void Start() 
        {
            _player = new TrueGearPlayer("546560","Half-Life:Alyx");
            _player.PreSeekEffect("PlayerBulletDamage");
            _player.PreSeekEffect("PlayerExplodeDamage");
            _player.PreSeekEffect("PlayerZombieDamage");
            _player.PreSeekEffect("ZhouZiheadcrabDamage");
            _player.PreSeekEffect("PlayerFlashdogDamage");
            _player.PreSeekEffect("PlayerManhackDamage");
            _player.PreSeekEffect("PlayerLaserDamage");
            _player.PreSeekEffect("PlayerAntlionDamage");
            _player.PreSeekEffect("PlayerOtherDamage");
            _player.Start();
            lowHeartBeatThred = new Thread(this.LowHeartBeat);
            lowHeartBeatThred.Start();
            midHeartBeatThred = new Thread(this.MidHeartBeat);
            midHeartBeatThred.Start();
            fastHeartBeatThred = new Thread(this.FastHeartBeat);
            fastHeartBeatThred.Start();
            leftreviverheartitemThred = new Thread(this.LeftReviverHeartItem);
            leftreviverheartitemThred.Start();
            rightreviverheartitemThred = new Thread(this.RightReviverHeartItem);
            rightreviverheartitemThred.Start();
            coughThred = new Thread(this.PlayerCough);
            coughThred.Start();
            playerusehealthstationThred = new Thread(this.PlayerUseHealthStation);
            playerusehealthstationThred.Start();
            playeropenhealthstationThred = new Thread(this.PlayerOpenHealthStation);
            playeropenhealthstationThred.Start();
        }

        public void StopSDK()
        {

            if (lowHeartBeatThred != null)
            {
                lowHeartBeatThred.Abort();
            }
            if (midHeartBeatThred != null)
            {
                midHeartBeatThred.Abort();
            }
            if (fastHeartBeatThred != null)
            {
                fastHeartBeatThred.Abort();
            }
            if (leftreviverheartitemThred != null)
            {
                leftreviverheartitemThred.Abort();
            }
            if (rightreviverheartitemThred != null)
            {
                rightreviverheartitemThred.Abort();
            }
            if (coughThred != null)
            {
                coughThred.Abort();
            }
            if (playerusehealthstationThred != null)
            {
                playerusehealthstationThred.Abort();
            }
            if (playeropenhealthstationThred != null)
            {
                playeropenhealthstationThred.Abort();
            }
        }  

        public void Play(string Event)
        {
            if (Form1.isDeath)
            {
                return;
            }
            _player.SendPlay(Event);
        }

        public void PlayAngle(string tmpEvent, float tmpAngle, float tmpVertical)
        {
            try
            {
                float angle = (tmpAngle - 22.5f) > 0f ? tmpAngle - 22.5f : 360f - tmpAngle;
                int horCount = (int)(angle / 45) + 1;

                int verCount = tmpVertical > 0.1f ? -4 : tmpVertical < -0.5f ? 8 : 0;


                EffectObject oriObject = _player.FindEffectByUuid(tmpEvent);

                EffectObject rootObject = EffectObject.Copy(oriObject);


                foreach (TrackObject track in rootObject.trackList)
                {
                    if (track.action_type == ActionType.Shake)
                    {
                        for (int i = 0; i < track.index.Length; i++)
                        {
                            if (verCount != 0)
                            {
                                track.index[i] += verCount;
                            }
                            if (horCount < 8)
                            {
                                if (track.index[i] < 50)
                                {
                                    int remainder = track.index[i] % 4;
                                    if (horCount <= remainder)
                                    {
                                        track.index[i] = track.index[i] - horCount;
                                    }
                                    else if (horCount <= (remainder + 4))
                                    {
                                        var num1 = horCount - remainder;
                                        track.index[i] = track.index[i] - remainder + 99 + num1;
                                    }
                                    else
                                    {
                                        track.index[i] = track.index[i] + 2;
                                    }
                                }
                                else
                                {
                                    int remainder = 3 - (track.index[i] % 4);
                                    if (horCount <= remainder)
                                    {
                                        track.index[i] = track.index[i] + horCount;
                                    }
                                    else if (horCount <= (remainder + 4))
                                    {
                                        var num1 = horCount - remainder;
                                        track.index[i] = track.index[i] + remainder - 99 - num1;
                                    }
                                    else
                                    {
                                        track.index[i] = track.index[i] - 2;
                                    }
                                }
                            }
                        }
                        if (track.index != null)
                        {
                            track.index = track.index.Where(i => !(i < 0 || (i > 19 && i < 100) || i > 119)).ToArray();
                        }
                    }
                    else if (track.action_type == ActionType.Electrical)
                    {
                        for (int i = 0; i < track.index.Length; i++)
                        {
                            if (horCount <= 4)
                            {
                                track.index[i] = 0;
                            }
                            else
                            {
                                track.index[i] = 100;
                            }
                            if (horCount == 1 || horCount == 8 || horCount == 4 || horCount == 5)
                            {
                                track.index = new int[2] { 0, 100 };
                            }

                        }
                    }
                }
                _player.SendPlayEffectByContent(rootObject);
                
            }
            catch (System.Exception ex)
            {
                _player.SendPlay(tmpEvent);
            }   
        }

        public void ConsoleO()
        { 
            
        }

        public void StartLowHeartBeat()
        {
            lowheartbeatMRE.Set();
        }

        public void StopLowHeartBeat()
        {
            lowCount = 0;
            lowheartbeatMRE.Reset();
        }

        public void StartMidHeartBeat()
        {
            midheartbeatMRE.Set();
        }

        public void StopMidHeartBeat()
        {
            midCount = 0;
            midheartbeatMRE.Reset();
        }

        public void StartFastHeartBeat()
        {
            fastheartbeatMRE.Set();
        }

        public void StopFastHeartBeat()
        {
            fastCount = 0;
            fastheartbeatMRE.Reset();
        }

        public void StartLeftReviverHeartItem()
        {
            leftreviverheartitemMRE.Set();
        }

        public void StopLeftReviverHeartItem()
        {
            leftreviverheartitemMRE.Reset();
        }

        public void StartRightReviverHeartItem()
        {
            rightreviverheartitemMRE.Set();
        }

        public void StopRightReviverHeartItem()
        {
            rightreviverheartitemMRE.Reset();
        }

        public void StartPlayerCough()
        {
            coughMRE.Set();
        }

        public void StopPlayerCough()
        {
            coughMRE.Reset();
        }

        public void StartPlayerUseHealthStation(int number)
        {
            shockCount = 0;
            shockNum = number;
            playerusehealthstationMRE.Set();
        }

        public void StopPlayerUseHealthStation()
        {
            shockCount = 0;
            shockNum = 0;
            playerusehealthstationMRE.Reset();
        }

        public void StartPlayerOpenHealthStation()
        {
            playeropenhealthstationMRE.Set();
        }

        public void StopPlayerOpenHealthStation()
        {
            playeropenhealthstationMRE.Reset();
        }
    }
}
