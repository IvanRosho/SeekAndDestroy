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
    public class RelativeKoordToAbsoluteConverter : IValueConverter, IMultiValueConverter {
        /// <summary>
        /// 0.5 => 250
        /// </summary>
        /// <param name="value"></param>
        /// <param name="targetType"></param>
        /// <param name="parameter"></param>
        /// <param name="culture"></param>
        /// <returns></returns>
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture) {
            var koord = (double)value;
            double offset = 0;
            if (parameter != null && parameter is double dp) {
                    offset = dp;
            }
            return koord * Settings.Default.CanvasSize - offset / 2;
        }

        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture) {
            if (values.Length < 2) return 0.0; 
            if (!(values[0] is double relative)) return 0.0; 
            if (!(values[1] is double size)) return 0.0;
            return Convert(relative, typeof(double), size, culture);
        }

        /// <summary>
        /// 250 => 0.5
        /// </summary>
        /// <param name="value"></param>
        /// <param name="targetType"></param>
        /// <param name="parameter"></param>
        /// <param name="culture"></param>
        /// <returns></returns>
        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) {
            double offset = 0;
            if (parameter != null && parameter is double dp) {
                    offset = dp;
                }
            var koord = (double)value + offset / 2;
            return koord / Settings.Default.CanvasSize;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture) {
            if (!(value is double absolute)) return new object[] { Binding.DoNothing, Binding.DoNothing };
            if (!(parameter is double size)) return new object[] { Binding.DoNothing, Binding.DoNothing };
            return new object[] { Convert(absolute, typeof(double), size, culture), Binding.DoNothing };
        }
    }

}
