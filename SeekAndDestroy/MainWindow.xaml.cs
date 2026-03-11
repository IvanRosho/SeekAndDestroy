using SeekAndDestroy.Properties;
using SeekAndDestroy.VM;
using System.ComponentModel;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace SeekAndDestroy {
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window {
        private MainVM vm;
        public MainWindow() {
            InitializeComponent();
            RadarField.Height = RadarField.Width = Settings.Default.CanvasSize;
            TargetOnCanvas.Height = TargetOnCanvas.Width = Settings.Default.TargetSize;
            SeekerOnCanvas.Height = SeekerOnCanvas.Width = Settings.Default.SeekerSize;
            this.DataContext = vm = new MainVM();
            //vm.PropertyChanged += Vm_PropertyChanged; 
            //vm.Target.PropertyChanged += (s, e) =>
            //{
            //    if (e.PropertyName == nameof(RadarObject.X))
            //        Animate(TargetOnCanvas, Canvas.LeftProperty, vm.Target.X);

            //    if (e.PropertyName == nameof(RadarObject.Y))
            //        Animate(TargetOnCanvas, Canvas.TopProperty, vm.Target.Y);
            //};

            //vm.Seeker.PropertyChanged += (s, e) =>
            //{
            //    if (e.PropertyName == nameof(RadarObject.X))
            //        Animate(SeekerOnCanvas, Canvas.LeftProperty, vm.Seeker.X);

            //    if (e.PropertyName == nameof(RadarObject.Y))
            //        Animate(SeekerOnCanvas, Canvas.TopProperty, vm.Seeker.Y);
            //};
        }

        //private void Vm_PropertyChanged(object sender, PropertyChangedEventArgs e) {
        //    if (e.PropertyName == nameof(MainVM.TargetXChanged))
        //        Animate(TargetOnCanvas, Canvas.LeftProperty, vm.Target.X);

        //    if (e.PropertyName == nameof(MainVM.TargetYChanged))
        //        Animate(TargetOnCanvas, Canvas.TopProperty, vm.Target.Y);
        //    if (e.PropertyName == nameof(MainVM.SeekerXChanged))
        //        Animate(SeekerOnCanvas, Canvas.LeftProperty, vm.Seeker.X);

        //    if (e.PropertyName == nameof(MainVM.SeekerYChanged))
        //        Animate(SeekerOnCanvas, Canvas.TopProperty, vm.Seeker.Y);
        //}

        private void Animate(UIElement element, DependencyProperty dp, double to) {
            var anim = new DoubleAnimation {
                To = to,
                Duration = TimeSpan.FromMilliseconds(Settings.Default.StepDuration),
                EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseOut }
            };

            element.BeginAnimation(dp, anim);
        }
    }
}