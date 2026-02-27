using SeekAndDestroy.Classes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SeekAndDestroy.VM{
    public abstract class RadarObject:BaseViewModel {
        private double x;
        private double y;
        private double dx;
        private double dy;
        public double X {
            get => x;
            set { x = value; RaisePropertyChanged(); } 
        }
        public double Y {
            get => y;
            set { y = value; RaisePropertyChanged(); }
        }
        public double DX {
            get => dx;
            set { dx = value; RaisePropertyChanged(); }
        }
        public double DY {
            get => dy;
            set { dy = value; RaisePropertyChanged(); }
        }
        public abstract void Step();
    }
}
