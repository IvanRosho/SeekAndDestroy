using SeekAndDestroy.Classes;
using SeekAndDestroy.Properties;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.VM
{
    public class Seeker : RadarObject {
        private PathPoint POI;
        public override void Step() {
            this.X += DX;
            this.Y += DY;
        }
        private int StepToTarget;
        public void SetTarget(double _targetX, double _targetY) { 
            this.DX = (this.X - _targetX) / StepToTarget;
            this.DY = (this.Y - _targetY) / StepToTarget;
            StepToTarget--;
        }

        public Seeker() { 
            StepToTarget = 10;
            this.POI = null;
        }

        public override string ToString() { 
            return $"X:{x:F2} Y:{y:F2}, dx:{dx:F2} dy:{dy:F2}";
        }

        public void SetPOI(PathPoint _poi) {
            if (this.POI != null) {
                double poiDX =_poi.X  - POI.X;
                double poiDY = _poi.Y - POI.Y;
                //Example: Canvas 550px, Seeker 50px. 550/50=11, but steps must be smaller once, that 10. that step = 1/10 = 0.1
                double stepD = 1.0 / ((Settings.Default.CanvasSize / Settings.Default.SeekerSize) - 1);
                //Diagonal
                if (poiDX == poiDY) {
                    int stepCount = (int)Math.Round(Math.Abs(poiDX) / stepD, 0);
                    this.DX = this.DY = poiDX / stepCount;
                }
                // move --> or <-- with small DY
                else if (Math.Abs(poiDX) > Math.Abs(poiDY)) {
                    int stepCount = (int)Math.Round(Math.Abs(poiDX) / stepD, 0);
                    this.DX = poiDX / stepCount;
                    this.DY = poiDY / stepCount;
                }
                // move up or down with small DX
                else {
                    int stepCount = (int)Math.Round(Math.Abs(poiDY) / stepD, 0);
                    this.DX = poiDX / stepCount;
                    this.DY = poiDY / stepCount;
                } 
            }
            this.POI = _poi;
        }

        public bool POIArrive => Math.Abs(this.X - POI.X) <= 0.001 && Math.Abs(this.Y - POI.Y) <= 0.001;
    }
}
