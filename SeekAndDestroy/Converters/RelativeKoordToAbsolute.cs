using SeekAndDestroy.Classes;
using SeekAndDestroy.Properties;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;

namespace SeekAndDestroy.Converters
{
    public class RelativeKoordToAbsoluteConverter : IMultiValueConverter {
        /// <summary>
        /// Convert relative Koords to Absolute
        /// 0.5, 50, 550 => 250 (0.5 * 550 - 50 / 2)
        /// </summary>
        /// <param name="values">
        /// double[]
        /// 0 - Relative koord
        /// 1 - Element Size (offset = ElSize/2
        /// 2 - Container Size. Default - Settings.Default.CanvasSize
        /// </param>
        /// <param name="targetType"></param>
        /// <param name="parameter"></param>
        /// <param name="culture"></param>
        /// <returns></returns>
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture) {
            if (values.Length < 2) return 0.0;
            double elementSize, relativeCoord, containerSize;
            if (!(values[0] is double)) return 0.0; 
            relativeCoord = (double)values[0];
            if (!(values[1] is double)) return 0.0;
            elementSize = (double)values[1];
            containerSize = (values.Count() >= 3 && (values[2] is double)) ? (double)values[2] : Settings.Default.CanvasSize;
            return relativeCoord * containerSize - elementSize / 2;
        }

        /// <summary>
        /// 250 => 0.5
        /// </summary>
        /// <param name="value"></param>
        /// <param name="targetType"></param>
        /// <param name="parameter">
        /// double[]
        /// 0 - Element Size (offset = ElSize/2
        /// 1 - Container Size. Default - Settings.Default.CanvasSize
        /// </param>
        /// <param name="culture"></param>
        /// <returns></returns>

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture) {
            if (!(value is double absoluteCoord)) return new object[] { Binding.DoNothing, Binding.DoNothing, Binding.DoNothing };
            double containerSize;
            if (parameter is double[] parArray) {
                containerSize = (parArray.Count()>=2) ? parArray[1] : Settings.Default.CanvasSize;
                return new object[] { (absoluteCoord + parArray[0] / 2) / containerSize, Binding.DoNothing, Binding.DoNothing };
            }
            return new object[] { Binding.DoNothing, Binding.DoNothing, Binding.DoNothing };
        }
    }
}
