using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Threading;

namespace SeekAndDestroy {
    /// <summary>
    /// Логика взаимодействия для MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window {
        public MainWindow() {
            InitializeComponent();
        }

        private void Zaxvat_Click(object sender, RoutedEventArgs e) {
            for (int i = 0; i < 100; i++) {
                Thickness m = new Thickness(Seeker.Margin.Left + 1, Seeker.Margin.Top + 1, 0, 0);
                Seeker.Margin=m;
                Thread.Sleep(10);
            }
        }
    }
}
