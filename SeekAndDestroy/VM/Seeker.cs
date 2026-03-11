using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.VM
{
    public class Seeker : RadarObject {
        public double Speed => 1.0/11.0;
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
            X = Y = 0.045;
        }

        public override string ToString() { 
            return $"X:{x:F2} Y:{y:F2}, dx:{dx:F2} dy:{dy:F2}";
        }
    }
}
