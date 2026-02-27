using SeekAndDestroy.Classes;
using SeekAndDestroy.Converters;
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
            set { 
                stat_P_i = value;
                RaisePropertyChanged();
            }
        }
        private double stat_t_i;
        public double Stat_t_i {
            get => stat_t_i;
            set {
                stat_t_i = value;
                RaisePropertyChanged();
            }
        }
        private double stat_n;
        public double Stat_n {
            get => stat_n;
            set {
                stat_n = value;
                RaisePropertyChanged();
            }
        }
        private double stat_k;
        public double Stat_k {
            get => stat_k;
            set {
                stat_k = value;
                RaisePropertyChanged();
            }
        }
        private double stat_P_n;
        public double Stat_P_n {
            get => stat_P_n;
            set {
                stat_P_n = value;
                RaisePropertyChanged();
            }
        }
        private double stat_t_n;
        public double Stat_t_n {
            get => stat_t_n;
            set {
                stat_t_n = value;
                RaisePropertyChanged();
            }
        }
        private double stat_m_n_s;
        public double Stat_m_n_s {
            get => stat_m_n_s;
            set {
                stat_m_n_s = value;
                RaisePropertyChanged();
            }
        }
        #endregion
        #region Target
        private double startTargetX;
        private double startTargetY;
        private RelativeKoordToAbsoluteConverter koordKonverter = new RelativeKoordToAbsoluteConverter();
        public double StartTargetX {
            get => (double)koordKonverter.Convert(Target.X, typeof(double), null, System.Globalization.CultureInfo.CurrentCulture);
            set {
                var trgValue = (double)koordKonverter.ConvertBack(value, typeof(double), null, System.Globalization.CultureInfo.CurrentCulture);
                Target.X = startTargetX = trgValue;
                RaisePropertyChanged();
            }
        }
        public double StartTargetY {
            get => (double)koordKonverter.Convert(Target.Y, typeof(double), null, System.Globalization.CultureInfo.CurrentCulture);
            set {
                var trgValue = (double)koordKonverter.ConvertBack(value, typeof(double), null, System.Globalization.CultureInfo.CurrentCulture);
                Target.Y = startTargetY = trgValue;
                RaisePropertyChanged();
            }
        }
        public double StartTargetSpeed {
            get => Target.Speed;
            set {
                Target.Speed = value;
                RaisePropertyChanged();
            }
        }
        public RadarTarget Target { get; set; } = new RadarTarget(0.5, 0.5, 2);
        #endregion
        #region Seeker
        public Seeker Seeker { get; set; } = new Seeker();
        #endregion
        #region Settings
        public ObservableCollection<SearchPath> SearchTypes { get; set; } = new ObservableCollection<SearchPath>();
        public SearchPath SelectedSearchType { get; set; }
        public bool DemoMode { get; set; } = true;
        public bool WithReturn { get; set; } = false;
        public int TotalRepeats { get; set; } = 6;
        #endregion
        #region Stat Props
        public string Status { get; set; } = "";
        #endregion

        public AsyncRelayCommand StartCommand { get; }
        public MainVM() {
            StartCommand = new AsyncRelayCommand(startMethod);
            LoadPathes();
            RaisePropertyChanged(nameof(Target));
            RaisePropertyChanged(nameof(Seeker));
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
            RaisePropertyChanged(nameof(SearchTypes));
            SelectedSearchType = SearchTypes.First();
            RaisePropertyChanged(nameof(SelectedSearchType));
        }
        private async Task startMethod() {
            await Task.Delay(100);

        }
    }
}
