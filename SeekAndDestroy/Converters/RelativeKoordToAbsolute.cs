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
    public class RelativeKoordToAbsoluteConverter : IValueConverter {
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
            double offset = Settings.Default.CanvasOffset;
            if (parameter != null && parameter is string prm && prm.ToLower() == "withoutoffset") {
                offset = 0;
            }
            return koord * Settings.Default.CanvasSize + offset;
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
            double offset = Settings.Default.CanvasOffset;
            if (parameter != null && parameter is string prm && prm.ToLower() == "withoutoffset") {
                offset = 0;
            }
            var koord = (double)value - offset;
            return koord / Settings.Default.CanvasSize;
        }
    }

}
