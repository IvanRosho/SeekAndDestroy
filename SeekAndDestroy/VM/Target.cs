using SeekAndDestroy.Properties;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.VM {
    public class Target : RadarObject {
        private double speed;
        public double Speed {
            set {
                speed = value / Settings.Default.CanvasSize;
                RaisePropertyChanged();
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="_x">X in absolute Coord</param>
        /// <param name="_y">Y in absolute Coord</param>
        /// <param name="_speed">Speed as relative speed(px)</param>
        public Target(double _x, double _y, double _speed) {
            x = _x;
            y = _y;
            speed = _speed;
        }
        public override void Step() {
            X += DX;
            Y += DY;
        }

        public override string ToString() {
            return $"X:{x:F2} Y:{y:F2}, speed:{speed:F2}, dx:{dx:F2} dy:{dy:F2}";
        }

        public void SetAngle() {
            Random rnd = new Random();
            DX = (Random.Shared.NextDouble() * 2.0 - 1.0) * speed;    // (-1..1) * speed 
            DY = Math.Sqrt(speed * speed - DX * DX);
        }

        public bool IsLost => x < 0.0 || y < 0.0 || x>1.0 || y>1.0;
    }
}
