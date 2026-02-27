using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.VM {
    public class RadarTarget: RadarObject {
        public double Speed { get; set; }
        public RadarTarget(double _x, double _y, double _speed){
            X = _x;
            Y = _y; 
            Speed = _speed;
            Random rnd = new Random();
            DX = (Random.Shared.NextDouble() * 2.0 - 1.0)*Speed;    // (-1..1) * speed 
            DY = Math.Sqrt(_speed * _speed - DX * DX);              // Pifagor from speed and DX
        }
        public override void Step() {
            X += DX;
            Y += DY;
        }
    }
}
