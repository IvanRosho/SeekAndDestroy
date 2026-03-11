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
            }
        }
        public bool IsSearch {
            get => isSearch;
            set {
                isSearch = value;
                RaisePropertyChanged();
            }
        }
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
            Status = "Двигаем цель!";
            Target.SetAngle();
            for (int i = 0; i < 20; i++) {
                Target.Step();
                await Task.Delay(100);
            }
            Status = "Опля!";
        }
    }
}
