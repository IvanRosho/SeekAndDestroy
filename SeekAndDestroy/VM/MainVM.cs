using SeekAndDestroy.Classes;
using SeekAndDestroy.Converters;
using SeekAndDestroy.Properties;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;

namespace SeekAndDestroy.VM
{
    public class MainVM : BaseViewModel {
        #region Stat Props
        private double stat_P_i;
        public double Stat_P_i {
            get => stat_P_i;
            private set { 
                stat_P_i = value;
                RaisePropertyChanged();
            }
        }
        private double stat_t_i;
        public double Stat_t_i {
            get => stat_t_i;
            private set {
                stat_t_i = value;
                RaisePropertyChanged();
            }
        }
        private double stat_n;
        public double Stat_n {
            get => stat_n;
            private set {
                stat_n = value;
                RaisePropertyChanged();
            }
        }
        private double stat_k;
        public double Stat_k {
            get => stat_k;
            private set {
                stat_k = value;
                RaisePropertyChanged();
            }
        }
        private List<double> stat_P_n = new List<double>();
        public double Stat_P_n {
            get => stat_P_n.Count > 0 ? stat_P_n.Average() : 0;
        }
        private List<double> stat_t_n = new List<double>();
        public double Stat_t_n {
            get => stat_t_n.Count > 0 ? stat_t_n.Average() : 0;
        }
        private List<double> stat_m_n_s = new List<double>();
        public double Stat_m_n_s {
            get => stat_m_n_s.Count > 0 ? stat_m_n_s.Average() : 0;
        }
        #endregion
        #region Target
        private double startTargetX;
        private double startTargetY;
        private RelativeKoordToAbsoluteConverter koordKonverter = new RelativeKoordToAbsoluteConverter();
        public double StartTargetX {
            get => (double)koordKonverter.Convert(new object[] { Target.X, Settings.Default.TargetSize }, typeof(double), null, System.Globalization.CultureInfo.CurrentCulture);
            set {
                var prm = new double[] { Settings.Default.TargetSize };
                var trgValue = (double)koordKonverter.ConvertBack(value, new Type[] { typeof(double), typeof(double), typeof(double) }, prm, System.Globalization.CultureInfo.CurrentCulture)[0];
                Target.X = startTargetX = trgValue;
                RaisePropertyChanged();
            }
        }
        public double StartTargetY {
            get => (double)koordKonverter.Convert(new object[] { Target.Y, Settings.Default.TargetSize }, typeof(double), null, System.Globalization.CultureInfo.CurrentCulture);
            set {
                var prm = new double[] { Settings.Default.TargetSize };
                var trgValue = (double)koordKonverter.ConvertBack(value, new Type[] { typeof(double), typeof(double), typeof(double) }, prm, System.Globalization.CultureInfo.CurrentCulture)[0];
                Target.Y = startTargetY = trgValue;
                RaisePropertyChanged();
            }
        }
        public double StartTargetSpeed {
            set {
                Target.Speed = value;
                RaisePropertyChanged();
            }
        }
        private Target _target;
        public Target Target { 
            get => _target;
            set {
                _target = value;
                RaisePropertyChanged();
            } 
        }
        #endregion
        #region Seeker
        private Seeker _seeker;
        public Seeker Seeker { 
            get => _seeker;
            set {
                _seeker = value;
                RaisePropertyChanged();
            } 
        } 
        #endregion
        #region Settings
        public ObservableCollection<SearchPath> SearchTypes { get; set; } = new ObservableCollection<SearchPath>();
        private SearchPath selectedSearchType;
        public SearchPath SelectedSearchType { 
            get => selectedSearchType;
            set { 
                selectedSearchType  = value;
                RaisePropertyChanged();
            }
        }
        private bool demoMode, withReturn;
        private string status;
        private int totalRepeats;
        public bool DemoMode {
            get => demoMode;
            set { 
                demoMode = value;
                RaisePropertyChanged();
            }
        }
        public bool WithReturn {
            get => withReturn;
            set {
                withReturn = value;
                RaisePropertyChanged();
            }
        }
        public int TotalRepeats {
            get => totalRepeats;
            set {
                totalRepeats = value;
                RaisePropertyChanged();
            }
        }
        #endregion
        #region Props
        public List<PathPoint> GraphPoints { get; private set; } = new List<PathPoint>();
        public ObservableCollection<PathPoint> SeekerPath { get; set; } = new ObservableCollection<PathPoint>();
        public string Status {
            get => status;
            set {
                status = value;
                RaisePropertyChanged();
            }
        }
        private bool isTargeting, isSearch;
        public bool IsTargeting {
            get => isTargeting;
            set {
                isTargeting = value;
                RaisePropertyChanged();
                RaisePropertyChanged(nameof(IsRun));
            }
        }
        public bool IsSearch {
            get => isSearch;
            set {
                isSearch = value;
                RaisePropertyChanged();
                RaisePropertyChanged(nameof(IsRun));
            }
        }
        public bool IsRun => isTargeting || isSearch;
        private List<RadarObject> RadarObjects;
        #endregion

        public AsyncRelayCommand StartCommand { get; }
        public MainVM() {
            StartCommand = new AsyncRelayCommand(startMethod);
            DemoMode = true;
            WithReturn = false;
            TotalRepeats = 6;
            Status = "Не запущен";
            Target = new Target(0.5,0.5,2);
            Seeker = new Seeker();
            RadarObjects = new List<RadarObject>() { Target, Seeker };
            IsTargeting = IsSearch = false;
            LoadPathes(); 
        }

        public async Task LoadPathes() {
            if (!Directory.Exists(Properties.Settings.Default.PathesRoute)) 
                return; 
            await Task.Run( ()=> {

                var files = Directory.GetFiles(Properties.Settings.Default.PathesRoute, "*.json");
                foreach (var file in files) {
                    SearchPath path = null;
                    try {
                        string json = File.ReadAllText(file);
                        path = JsonSerializer.Deserialize<SearchPath>(json, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                        SearchTypes.Add(path);
                    }
                    catch (Exception ex) { 
                        continue;
                    }
                }
            });
            SelectedSearchType = SearchTypes.First();
        }
        private async Task startMethod() {
            Seeker.X = selectedSearchType.Points.First().X;
            Seeker.Y = selectedSearchType.Points.First().Y;
            Seeker.SetPOI(selectedSearchType.Points.First());
            StatClear();
            IsSearch = !demoMode;
            Target.SetAngle();
            if (demoMode) {
                Target.X = Target.Y = -50;
                Target.DX = Target.DY = 0;
                Status = $"Демонстрация режима {selectedSearchType.Name}";
                await Search();
            }
            else {
                Target.X = startTargetX;
                Target.Y = startTargetY;
                Status = "Поиск цели..."; 
                for (Stat_n = 1; Stat_n <= TotalRepeats; Stat_n++) {

                    await Search();
                    stat_P_n.Add(stat_P_i);
                    stat_t_n.Add(stat_t_i);
                    stat_m_n_s.Add(stat_n);
                    RaisePropertyChanged(nameof(Stat_P_n));
                    RaisePropertyChanged(nameof(Stat_t_n));
                    RaisePropertyChanged(nameof(Stat_m_n_s));
                    await Task.Run(() => {
                        Thread.Sleep(TimeSpan.FromSeconds(15));
                    });
                }
            }
        }

        private void StatClear() {
            Stat_k = 0;
            Stat_n = 0;
            Stat_P_i = 0;
            Stat_t_i = 0;
            stat_m_n_s.Clear();
            stat_P_n.Clear();
            stat_t_n.Clear();
            SeekerPath.Clear();
            RaisePropertyChanged(nameof(Stat_m_n_s));
            RaisePropertyChanged(nameof(Stat_P_n));
            RaisePropertyChanged(nameof(Stat_t_n));
        }

        private async Task Search() {
            List<PathPoint> points = [.. selectedSearchType.Points];
            if (withReturn) { 
                var pointsReturn = new List<PathPoint>(points);
                pointsReturn.Reverse();
                pointsReturn.RemoveAt(0);
                points.AddRange(pointsReturn);
            }
            SeekerPath.Add(selectedSearchType.Points.First());
            SeekerPath.Add(selectedSearchType.Points.First());
            for (int j = 1; j < points.Count; j++) {
                Seeker.SetPOI(points[j]);
                while (!Seeker.POIArrive) {
                    await Step();
                    SeekerPath.Remove(SeekerPath.Last());
                    SeekerPath.Add(new PathPoint(Seeker.X, Seeker.Y));
                    if (isTargetInSeeker) {
                        await Targeting();
                        return;
                    }
                    else if (!demoMode && Target.IsLost) {
                        LostTarget();
                        return;
                    }
                    Stat_t_i += 0.1;
                }
            }
        }

        private async Task Targeting() {
            Status = "Наведение на цель!";
            while (!isTargetFinded) { 
                await Step();
                Seeker.SetTarget(Target.X, Target.Y);
                if (Target.IsLost) {
                    LostTarget();
                    return;
                }
            }
            Status = "Цель поймана!";
            Stat_P_i = 1;
            Stat_k++;
        }

        private void LostTarget() {
            Stat_P_i = 0;
            Status = "Цель потеряна!";
        }

        private async Task Step() {
            foreach (var item in RadarObjects) { 
                item.Step();
            }
            GraphPoints.Clear();
            double i = 0;
            Random rnd = new Random();
            double getNoise(double noiseWidth) { 
                return (Random.Shared.NextDouble() - 1.0) / noiseWidth;
            }
            if (!isTargeting) {
                for (i = 0.0; i <= 1.0; i += 0.02)
                    GraphPoints.Add(new PathPoint(i, 0.7 + getNoise(4.0)));
            }
            else {
                double sigma = 0.12;
                double mu = 0.5;
                for (i = 0.0; i <= 1.0; i += 0.02) {
                    if (!isTargeting) {
                        for (i = 0.0; i <= 1.0; i += 0.02)
                            GraphPoints.Add(new PathPoint(i, 0.5 + getNoise(4.0)));
                    }
                    double gauss = 0.9 * Math.Exp(-((i - mu) * (i - mu)) / (2 * sigma * sigma));
                    //1 - gauss - Y Reverse
                    GraphPoints.Add(new PathPoint(i, 1 - gauss + getNoise(8.0)));
                }
            }
            await Task.Run(() => {
                RaisePropertyChanged(nameof(GraphPoints));
                Thread.Sleep(100);
            });
        }

        private bool isTargetInSeeker {
            get {
                double range = Settings.Default.SeekerSize / Settings.Default.CanvasSize / 2.0;
                return (Seeker.X - Target.X <= range) && (Seeker.Y - Target.Y <= range); 
            }
        }

        private bool isTargetFinded { 
            get => Math.Abs(Target.X - Seeker.X) <=0.0001 && Math.Abs(Target.Y - Seeker.Y) <= 0.0001;
        }
    }
}
