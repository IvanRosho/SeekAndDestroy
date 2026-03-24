using SeekAndDestroy.Properties;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.Classes {
    public class PathPoint {
        public double X { get; set; }
        public double Y { get; set; }

        public PathPoint(double x, double y) {
            //Auto Offset, when x is 0 or 1
            var offset = Settings.Default.SeekerSize / Settings.Default.CanvasSize;
            x = (x >= 1 ? 1 - offset : (x <= 0 ? 0 + offset : x));
            y = (y >= 1 ? 1 - offset : (y <= 0 ? 0 + offset : y));
            X = x; 
            Y = y; 
        }
    }
}
