using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.VM
{
    public class Seeker : RadarObject {
        public double Speed => 5.0;
        public override void Step() {
            this.X += DX;
            this.Y += DY;
        }

        public void SetTarget(double _targetX, double _targetY) { 
            this.DX = (this.X - _targetX) / 10.0;
            this.DY = (this.Y - _targetY) / 10.0;
        }
    }
}
