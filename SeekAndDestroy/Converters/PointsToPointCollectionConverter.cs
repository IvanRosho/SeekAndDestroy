using SeekAndDestroy.Classes;
using SeekAndDestroy.Properties;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;

namespace SeekAndDestroy.Converters
{
    public class PointsToPointCollectionConverter : IValueConverter {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture) {
            var points = value as IEnumerable<PathPoint>;
            var pc = new PointCollection();
            foreach (var p in points)
                pc.Add(new Point(p.X * Settings.Default.CanvasSize + Settings.Default.SeekerSize, p.Y * Settings.Default.CanvasSize + Settings.Default.SeekerSize));
            return pc;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) {
            throw new NotImplementedException();
        }
    }

}
