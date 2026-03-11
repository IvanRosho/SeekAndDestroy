
program PoiskIZaxvat_BI;

USES GraphABC;

const
  Image_3 = 'vzr.bmp';

type
  m = (Up, Left, Down, Right);

var
  bp: integer;
  pos_x, pos_y: real; //счетчики
  to_left: boolean;
  path: array[1..2, 1..100000] of real; //массив "пути" цели
  target_x, target_y, target_dx, target_dy: real; //позиция и скорости цели
  target_status: integer; // -1 - потеряли цель, 0 - не нашли, 1 - захватили цель
  col_points: integer; //сколько цель прошла шагов
  vzriv: Picture;
  sound: system.Media.SoundPlayer;  
  Col_step: integer; //количество шагов в итерации спирали
  step_dx, step_dy: real; //шаг по X и Y
  moving: m;
  spiral_end: boolean;
  radar_path: array[1..42, 1..2] of real;
  radar_dx, radar_dy: real;
  radar_step_x, radar_step_y: integer;
  time_to_target_status: array of real;
  number_target_status, num_proch:integer;
  turn_p:integer; //указатель на линию в повороте
  points_snake1: array[1..22,1..2] of real; //змейка простая и обратная
  points_snake2: array[1..44,1..2] of real; //змейка с оборотом
  points_spiral1: array[1..27,1..2] of real; //спираль
  points_spiral2: array[1..44,1..2] of real; //спираль
  temp:real;
  target_setting: boolean; //true - цель движется с отражением после уничтожения, false - цель появляется в заданной точке после уничтожения
  target_point_x, target_point_y:real; //для движения из точки
  target_speed:real;
  PP:real;
  k:integer;
  ms,p:real;

{ ----------------------------- MAIN --------------------------- }

function sr_vr_z():real;
var
sr: real;
srr:real;
begin
sr:=0;
srr:=0;
for var ii:=0 to time_to_target_status.length-1 do if time_to_target_status[ii]<>0.0 then  begin
	sr:=sr+time_to_target_status[ii];
	srr:=srr+1;
end;
result:=(round(sr/(srr)*100))/100.0;
end;

procedure stat(step:real); //step - доля шага в единице
begin
 if (num_proch >= number_target_status) then  num_proch:=num_proch-1;
 time_to_target_status[num_proch]:=time_to_target_status[num_proch]+step;
 temp:=(round(time_to_target_status[num_proch]*100.0))/100.0;
 if (target_status<=0) then p:=0 else p:=1;
 textout(1000, 520, 'Расчетные значения для текущего цикла:');
 textout(1025, 540, 'P(i) = ' + FloatToStr(p));
 textout(1025, 560, 't(i) = '+FloatToStr(temp));
 textout(1025, 580, 'n = ' + IntToStr(num_proch+1));
 textout(1125, 580, 'k = ' + IntToStr(k+1));
 //textout(1025, 600, 'm(s) = '+ FloatToStr(round((p/temp)*100)/100.0));
 textout(1000, 620, 'Расчетные значения, усредненные по всем циклам:');
 textout(1025, 640, 'P(n) = ' + FloatToStr(round ((PP/(num_proch+1))*100)/100.0));
 textout(1025, 660, 't(n) = '+sr_vr_z);
 textout(1025, 680, 'm(n(s)) = '+ FloatToStr(round(((PP/(num_proch+1))/sr_vr_z)*100)/100.0));
 redraw;
end;

procedure set_target;
const pi=3.14159;
var max_x, max_y:real;
angle:real;
begin
  if (target_setting=true) then begin
	//if (num_proch=-1) then begin num_proch:=num_proch+1; exit; end;//потому что не надо отфутболивать цель в первом проходе
	max_x:=550-target_x;
	max_y:=550-target_y;
	if ((max_x<target_x) and (max_x<max_y) and (max_x<target_y)) then target_dx:=target_dx*-1;
	if ((target_y<max_x) and (target_y<max_y) and (target_y<target_x)) then target_dy:=target_dy*-1;
	if ((target_x<max_x) and (target_x<max_y) and (target_x<target_y)) then target_dx:=target_dx*-1;
	if ((max_y<max_x) and (max_y<target_y) and (max_y<target_x)) then target_dy:=target_dy*-1;
  end
  else begin
	target_x:=target_point_x;
	target_y:=target_point_y;
	if (number_target_status=4) then begin
		angle:=10+((num_proch)*90.0)/(180.0/pi); //определяем угол отклонения от вертикали в радианах
	end;
	if (number_target_status=6) then begin
		angle:=10+((num_proch)*60.0)/(180.0/pi); //определяем угол отклонения от вертикали в радианах
	end;
	if (number_target_status=12) then begin
		angle:=10+((num_proch)*30.0)/(180.0/pi); //определяем угол отклонения от вертикали в радианах
	end;
	target_dx:=sin(angle)*target_speed;   //dx цели это синус угла
	target_dy:=cos(angle)*target_speed;  //dy цели это отрицательный косинус угла
  end;
end;

procedure lost_target;
begin
  time_to_target_status[num_proch]:=1; //так надо
  stat(0.0);
  SetFontSize(14);
  //TextBold;
  textout(300, 650, 'Пропуск цели.');
  num_proch:=num_proch+1;
  //k:=k+1;
  SetFontSize(9);
  set_target;
  redraw;
  readln;
end;

function get_y(x: real): integer;
begin			  //не трогать 45!!!!
  Result := Round(45 + ((-50 / 550) * (x - 50))); //вычисление "добавки" по Y для отрисовки, это линейная интерполяция по осевым точкам
end;//50,150 и 550,50

procedure target_move(b: boolean);//false для змейки, true для спиральки
var
  sens: integer;
begin
  if (b = false) then sens := 32 else sens := 27; //32 27
  target_x := target_x + target_dx;
  target_y := target_y + target_dy;
  col_points := col_points + 1; 
  path[1, col_points] := target_x; //запомнили точку маршрута
  path[2, col_points] := target_y;
  if (sqrt((target_x - pos_x) * (target_x - pos_x) + (target_y - pos_y) * (target_y - pos_y)) <= sens) then // чувствительность захвата,чем больше число,тем меньше возможная площадь цели в курсоре при захвате
	target_status := 1; //проверка на поимку,если расстояние между курсором и целью меньше 25 единиц,значит поймали цель
  if ((target_x >= 550.0) or (target_x <= 0.0) or (target_y >= 550.0) or (target_y <= 0.0)) then target_status:=-1; //пропустили
end;

procedure render;
begin
  clearwindow;
  SetPenColor(clBlack); 
  SetPenWidth(1);
  rectangle(1100, 75, 1200, 175); textout(1135, 115, 'ДСП');
  line(1150, 175, 1150, 250); line(1160, 230, 1150, 250); line(1140, 230, 1150, 250); textout(1185, 190, 'Uп');  line(1175, 190, 1175, 220); line(1175, 220, 1170, 210); line(1175, 220, 1180, 210);
  rectangle(1100, 250, 1200, 350); textout(1170, 325, 'ПРР');  line(1150, 250, 1150, 270);
  line(1150, 350, 1150, 400); line(1160, 370, 1150, 390); line(1140, 370, 1150, 390);
  rectangle(1100, 390, 1200, 450); textout(1130, 415, 'ПрОК'); line(1150, 350, 1150, 330);
  line(1100, 430, 955, 385); line(1100, 420, 955, 375);  line(955, 385, 970, 395); line(955, 375, 975, 375); 
  rectangle(900, 50, 1000, 100);   textout(930, 70, 'ИУРок'); 
  rectangle(900, 250, 1000, 350);   textout(940, 290, 'ОК');  line(1100, 300, 1120, 300);
  line(1000, 300, 1100, 300); line(1080, 290, 1100, 300); line(1080, 310, 1100, 300); textout(1030, 270, 'Uц');  line(1020, 290, 1060, 290); line(1060, 290, 1050, 285); line(1060, 290, 1050, 295);
  line(950, 250, 950, 100); line(960, 120, 950, 100); line(940, 120, 950, 100); textout(980, 130, 'Uy, Uz');
  line(945, 350, 945, 410);  line(955, 350, 955, 410);  line(950, 440, 950, 480);  
  circle(950, 425, 20); 
  arc(950, 425, 30, 180, 360);  arc(950, 425, 40, 240, 300);  arc(950, 425, 40, 150, 210); 
  line(930, 460, 940, 468);   line(930, 460, 945, 460);   line(905, 415, 915, 405);  line(915, 405, 915, 420); 
  line(920, 480, 980, 480); 
  line(900, 300, 900, 170); line(910, 190, 900, 170); line(890, 190, 900, 170); textout(860, 170, 'Yc');       // Система координат Yc 
  line(900, 300, 830, 350); line(840, 330, 830, 350); line(850, 345, 830, 350); textout(825, 355, 'Zc');       // Система координат Zc
  line(900, 300, 780, 300); line(800, 290, 780, 300); line(800, 310, 780, 300); textout(805, 305, 'Xc');       // Система координат Xc  
  textout(885, 270, 'O');    // Система координат O - центр
  SetBrushColor(clBlack); circle(900, 300, 5); circle(1150, 270, 5); circle(1120, 300, 5);    circle(1180, 300, 5); circle(1150, 330, 5);    SetBrushColor(clWhite);  // Жирные точки
  line(1180, 300, 1230, 300); line(1230, 300, 1210, 290); line(1230, 300, 1210, 310); textout(1210, 270, 'в СУ');       // Система координат Xc  
  // Поле Обзора  
  SetPenStyle(psSolid);
  SetPenColor(clBlack);
  SetPenWidth(2);
  Line(50, 50, 600, 0); Line(600, 0, 600, 550); Line(600, 550, 50, 600); Line(50, 600, 50, 50); // поле обзора большое
  SetPenStyle(psDash);
  SetPenWidth(1);
  Line(325, 0, 325, 590); Line(325, 0, 320, 20); Line(325, 0, 330, 20); textout(340, 0, 'Y'); Line(40, 325, 625, 275); Line(605, 270, 625, 275);   Line(605, 285, 625, 275);  textout(640, 270, 'Z');  // центр. линии
  line(900, 300, 325, 575);   line(900, 300, 325, 25); // линии поля обзора
  arc(800, 300, 100, 130, 230);   line(735, 225, 715, 235);   line(735, 225, 725, 245);   line(737, 380, 715, 370);  line(737, 380, 735, 355); textout(710, 315, '2Wобз');
  SetPenColor(clBlack);
  SetPenStyle(psSolid);
end;

procedure grafik;
var
  mu: real;
  gauss: real;
begin
  mu := 90; //центр гауссоиды
  SetPenWidth(2);
  SetPenColor(clBlack);
  MoveTo(670, 630); LineTo(870, 630); LineTo(865, 635); MoveTo(870, 630); LineTo(865, 625);
  MoveTo(670, 660); LineTo(670, 530); LineTo(665, 535); MoveTo(670, 530); LineTo(675, 535);  //Оси
  SetPenColor(clRed);
  SetPenStyle(psSolid);
  if (target_status <= 0) then begin//рисуем прямую с шумом
	MoveTo(671, 580);
	SetFontSize(11);
	LineTo(860, 580);   textout(870, 570, 'Uсраб');   textout(680, 520, 'U(tz)');    textout(880, 630, 'tz');     //линия "срабатывания"
	SetFontSize(9);
	MoveTo(671, 660);
	SetPenColor(clGreen);
  SetPenWidth(1);
	for var t := 1 to 180 do LineTo(671 + t, 620 - round(random(25)));
  end
  else begin
	MoveTo(671, 580);
	SetFontSize(11);
	LineTo(860, 580);   textout(870, 570, 'Uсраб');   textout(680, 520, 'U(tz)');    textout(880, 630, 'tz');    //линия "срабатывания"
	SetFontSize(9);
	SetPenColor(clGreen);
	MoveTo(671, 560);
  SetPenWidth(1);
	for var t := 1 to 180 do 
	begin
	  gauss := 80 * Exp(-(((t - mu) * (t - mu)) / (2 * 10 * 10))) + ((random - random) * 15);//сигма 10, шум гауссоиды 15, амплитуда гауссоиды 80
	  LineTo(671 + t, Round(610 - gauss));
	end;
  end;
end;

procedure target_status_move(b: boolean);
begin
  render;
  pos_x := pos_x + target_dx;
  pos_y := pos_y + target_dy;
  target_move(b);
  SetPenColor(ClGreen);
  Line(50 + (round(pos_x - 25)),  (round(pos_y)) + get_y(pos_x - 25) + 25,  50 + (round(pos_x + 25)),   (round(pos_y)) + get_y(pos_x + 25) + 25);
  Line(50 + (round(pos_x + 25)),  (round(pos_y)) + get_y(pos_x + 25) + 25,  50 + (round(pos_x + 25)),   (round(pos_y)) + get_y(pos_x + 25) - 24);
  Line(50 + (round(pos_x + 25)),  (round(pos_y)) + get_y(pos_x + 25) - 24,  50 + (round(pos_x - 25)),   (round(pos_y)) + get_y(pos_x - 25) - 24);
  Line(50 + (round(pos_x - 25)),  (round(pos_y)) + get_y(pos_x - 25) - 24,  50 + (round(pos_x - 25)),   (round(pos_y)) + get_y(pos_x - 25) + 25);
  Line(50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25), 50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25));       // Центр. линии
  Line(50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) + 28, 50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) - 24);  
  SetPenWidth(5);   
  for var j := 1 to col_points - 1 do 
	Line(50 + (round(path[1, j])),  (round(path[2, j])) + get_y(path[1, j]),  50 + (round(path[1, j + 1])),   (round(path[2, j + 1])) + get_y(path[1, j + 1]));
  SetPenColor(clRed); 
  SetPenWidth(3);
  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 2
  SetPenWidth(3);  
  SetPenColor(clBlack);
  SetFontSize(14);
  textout(300, 650, 'Цель захвачена.');
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1120, 300);  line(1150, 330, 1180, 300);      SetPenWidth(1);   SetPenColor(clBlack);   // Ключи
  SetFontSize(9);
  redraw;
  readln;  
end;

procedure DrawKursor();
var kk:integer;
begin
  SetPenWidth(1);
  SetPenColor(clGreen);
  Line(50 + (round(pos_x - 25)),  (round(pos_y)) + get_y(pos_x - 25) + 25,  50 + (round(pos_x + 25)),   (round(pos_y)) + get_y(pos_x + 25) + 25);
  Line(50 + (round(pos_x + 25)),  (round(pos_y)) + get_y(pos_x + 25) + 25,  50 + (round(pos_x + 25)),   (round(pos_y)) + get_y(pos_x + 25) - 24);
  Line(50 + (round(pos_x + 25)),  (round(pos_y)) + get_y(pos_x + 25) - 24,  50 + (round(pos_x - 25)),   (round(pos_y)) + get_y(pos_x - 25) - 24);
  Line(50 + (round(pos_x - 25)),  (round(pos_y)) + get_y(pos_x - 25) - 24,  50 + (round(pos_x - 25)),   (round(pos_y)) + get_y(pos_x - 25) + 25);
  Line(50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25), 50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25));       // Центр. линии
  Line(50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) + 28, 50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) - 24); 
  if (target_status=0) then begin
	SetPenWidth(5);
	SetPenColor(clGreen);
	MoveTo(75,25+get_y(25));
	if ((bp=31) or (bp=21) ) then begin //не надо рисовать обратку
		for var k:=1 to turn_p do lineto(round(points_snake1[k,1]+50),round(points_snake1[k,2])+get_y(points_snake1[k,1]));
		//if (turn_p>18) then moveto(round(points_snake1[18-(turn_p-18),1]+50),round(points_snake1[18-(turn_p-18),2])+get_y(points_snake1[18-(turn_p-18),1]));
	end;
	if (bp=32) or (bp=22) then begin
	  if (turn_p>21) then begin 
		kk:=22;
		moveto(575,525+get_y(525));		
		end
		else kk:=1;
		for var k:=kk to turn_p do lineto(round(points_snake2[k,1]+50),round(points_snake2[k,2])+get_y(points_snake2[k,1]));
	end;
	if (bp=41) or (bp=51) then begin
		MoveTo(round(points_spiral1[1,1]+50),round(points_spiral1[1,2])+get_y(points_spiral1[1,1]));
		for var k:=1 to turn_p do lineto(round(points_spiral1[k,1]+50),round(points_spiral1[k,2])+get_y(points_spiral1[k,1]));
	end;
	if (bp=42) or (bp=52) then begin
		if (turn_p>21) then begin 
		kk:=22;
		MoveTo(round(points_spiral2[22,1]+50),round(points_spiral2[22,2])+get_y(points_spiral2[22,1]));		
		end
		else begin kk:=1; MoveTo(round(points_spiral2[1,1]+50),round(points_spiral2[1,2])+get_y(points_spiral2[1,1]));
		MoveTo(round(points_spiral2[1,1]+50),round(points_spiral2[1,2])+get_y(points_spiral2[1,1]));end;
		for var k:=kk to turn_p do lineto(round(points_spiral2[k,1]+50),round(points_spiral2[k,2])+get_y(points_spiral2[k,1]));
	end;
	if (bp=72) or (bp=62) or (bp=71) or (bp=61) then begin
	if ((turn_p>=21) and ((bp=62) or (bp=72))) then begin 
		kk:=21; 
		moveto(575,525+get_y(525));	
	end else kk:=1;
		for var k:=kk to turn_p do lineto(round(radar_path[k,1]+50),round(round(radar_path[k,2])+get_y(radar_path[k,1])));
	end;
		lineto(50+round(pos_x),round(pos_y) + get_y(pos_x + 25));
  end;
end;

procedure Turn(b:boolean); //true для разворачивающейся, false для сворачивающейся
begin
  turn_p:=turn_p+1;
  if (b=true) then begin
	if (moving = Up) then begin
	  step_dx := 50;
	  step_dy := 0;
	  moving := Right;
	  Col_step := Col_step + 1; //каждые 2 прохода количество шагов увеличивается на 1
	  exit;
	end;
	if (moving = Right) then begin
	  step_dx := 0;
	  step_dy := 50;
	  moving := Down;
	  exit;
	end;
	if (moving = Down) then begin
	  step_dx := -50;
	  step_dy := 0;
	  moving := Left;
	  Col_step := Col_step + 1; //каждые 2 прохода количество шагов увеличивается на 1
	  exit;
	end;
	if (moving = Left) then begin
	  step_dx := 0;
	  step_dy := -50;
	  moving := Up;
	  exit;
	end;
  end
  else begin
	if ((Col_step=10) and (moving = Right)) then Col_step:=Col_step+1;
	if (moving = Up) then begin
	  step_dx := -50;
	  step_dy := 0;
	  moving := Left;
	  exit;
	end;
	if (moving = Right) then begin
	  step_dx := 0;
	  step_dy := -50;
	  moving := Up;
	  Col_step := Col_step - 1; //каждые 2 прохода количество шагов уменьшается на 1
	  exit;
	end;
	if (moving = Down) then begin
	  step_dx := 50;
	  step_dy := 0;
	  moving := Right;
	  exit;
	end;
	if (moving = Left) then begin
	  step_dx := 0;
	  step_dy := 50;
	  moving := Down;
	  Col_step := Col_step - 1; //каждые 2 прохода количество шагов уменьшается на 1
	  exit;
	end;
  end;
end;

function getmax() : integer;
begin
  if radar_step_x > radar_step_y then result := radar_step_x else result := radar_step_y;
end;

procedure read_target;
var varik:integer;
begin
  NormalizeWindow;
  SetWindowSize(800, 600);
  CenterWindow;
  clearwindow;
  target_x:=0.0; target_y:=0.0;
  target_dx:=-11.0; target_dy:=-11.0; //чтобы с предыдущего раза не подставились
  num_proch:=0; varik:=2; target_speed:=-10; number_target_status:=0;
  //while (varik<=0) or (varik>2) do begin
	//textout(50,30, 'Выбор эталонной трассы движения цели в пределах поля обзора:');
	//textout(50,50, '1-цель случайно меняет начально заданное направление своего движения в каждом новом цикле просмотра поля обзора');
	//textout(50,70, '2-цель последовательно перемещается по лувой трассе,при каждом новом цикле возвращаясь в заданную точку поля обзора');
	//redraw;
	//readln(varik);
  //end;
  while (target_x<10.0) or (target_x>540.0) do begin
	textout(50,30, 'Введите начальное положение цели в поле обзора по оси Z в пределах от 10 до 540');
	redraw;
	readln(target_x);
	target_point_x:=target_x;
  end;
  while (target_y<10.0) or (target_y>540.0) do begin
	textout(50,50, 'Введите начальное положение цели в поле обзора по оси Y в пределах от 10 до 540');
	redraw;
	readln(target_y);
	target_point_y:=target_y;
  end;
  if (varik=1) then begin
	target_setting:=true;
	while (target_dx<-4.0) or (target_dx>4.0) do begin
		textout(50,130, 'Введите начальную скорость цели по оси Z в пределах от -4 до 4');
		redraw;
		readln(target_dx);
	end;
	while (target_dy<-4.0) or (target_dy>4.0) do begin
		textout(50,150, 'Введите начальную скорость цели по оси Y в пределах от -4 до 4');
		redraw;
		readln(target_dy);
	end;
	while (number_target_status<1) or (number_target_status>100) do begin
		textout(50,170, 'Введите количество циклов просмотра поля обзора - от 1 до 18');
		redraw;
		readln(number_target_status);
	end;
  end
  else begin
	target_setting:=false;
	while (target_speed<0) or (target_speed>8.0) do begin
		textout(50,70, 'Введите начальную скорость цели в пределах от 0 до 8');
		redraw;
		readln(target_speed);
	end;
	while ((number_target_status<>6) and (number_target_status<>12) and (number_target_status<>18)) do begin
		textout(50,90, 'Введите количество циклов просмотра поля обзора - 6, 12, 18 раз');
		redraw;
		readln(number_target_status);
	end;
	
  end;
  time_to_target_status:= new real[number_target_status+1];
  set_target;
  PP:=0;
  ms:=0;
end;

procedure zaxvat;
var delta_x, delta_y:real;
begin
  SetPenColor(clBlack);
  delta_x:=(target_x-pos_x)/5.0; //чтобы не перебежать цель
  delta_y:=(target_y-pos_y)/5.0; //чтобы не перебежать цель
  PP:=0+PP+p;
  ms:=0+ms+p;
  k:=k+1;
  for var sh := 1 to 5 do 
  begin//шагов от 50 до 55
	pos_x:=pos_x+delta_x;
	pos_y:=pos_y+delta_y;
	target_status_move(false);
	grafik;
	stat(0.0);
	redraw;
	readln;
  end;
  target_x := target_x - target_dx;
  target_y := target_y - target_dy;

  vzriv := Picture.Create(Image_3); vzriv.Load(Image_3);
  vzriv.Draw(30 + Round(target_x), (round(target_y)) + get_y(target_x) - 30, 60, 60);
  sound := new system.Media.SoundPlayer;
  sound.SoundLocation := 'vzryv.wav';
  sound.Play;
  SetPenWidth(3);  
  SetPenColor(clBlack);
  SetFontSize(14);
  textout(300, 650, 'Цель уничтожена.');
  
  SetFontSize(9);
  num_proch:=num_proch+1;
  redraw;
  set_target;
  readln;
end;

procedure set_pathes;
begin
radar_path[1, 1] := 25; radar_path[1, 2] := 25;
  radar_path[2, 1] := 525; radar_path[2, 2] := 525;
  radar_path[3, 1] := 425; radar_path[3, 2] := 525;
  radar_path[4, 1] := 125; radar_path[4, 2] := 25;
  radar_path[5, 1] := 225; radar_path[5, 2] := 25;
  radar_path[6, 1] := 325; radar_path[6, 2] := 525;
  radar_path[7, 1] := 225; radar_path[7, 2] := 525;
  radar_path[8, 1] := 325; radar_path[8, 2] := 25;
  radar_path[9, 1] := 425; radar_path[9, 2] := 25;
  radar_path[10, 1] := 125; radar_path[10, 2] := 525;
  radar_path[11, 1] := 25; radar_path[11, 2] := 525;
  radar_path[12, 1] := 525; radar_path[12, 2] := 25;
  radar_path[13, 1] := 525; radar_path[13, 2] := 125;
  radar_path[14, 1] := 25; radar_path[14, 2] := 425;
  radar_path[15, 1] := 25; radar_path[15, 2] := 325;
  radar_path[16, 1] := 525; radar_path[16, 2] := 225;
  radar_path[17, 1] := 525; radar_path[17, 2] := 325;
  radar_path[18, 1] := 25; radar_path[18, 2] := 225;
  radar_path[19, 1] := 25; radar_path[19, 2] := 125;
  radar_path[20, 1] := 525; radar_path[20, 2] := 425; //1 круг
  radar_path[21, 1] := 525; radar_path[21, 2] := 525;
  radar_path[22, 1] := 25; radar_path[22, 2] := 25;
  radar_path[23, 1] := 125; radar_path[23, 2] := 25;
  radar_path[24, 1] := 425; radar_path[24, 2] := 525;
  radar_path[25, 1] := 325; radar_path[25, 2] := 525;
  radar_path[26, 1] := 225; radar_path[26, 2] := 25;
  radar_path[27, 1] := 325; radar_path[27, 2] := 25;
  radar_path[28, 1] := 225; radar_path[28, 2] := 525;
  radar_path[29, 1] := 125; radar_path[29, 2] := 525;
  radar_path[30, 1] := 425; radar_path[30, 2] := 25;
  radar_path[31, 1] := 525; radar_path[31, 2] := 25;
  radar_path[32, 1] := 25; radar_path[32, 2] := 525;
  radar_path[33, 1] := 25; radar_path[33, 2] := 425;
  radar_path[34, 1] := 525; radar_path[34, 2] := 125;
  radar_path[35, 1] := 525; radar_path[35, 2] := 225;
  radar_path[36, 1] := 25; radar_path[36, 2] := 325;
  radar_path[37, 1] := 25; radar_path[37, 2] := 225;
  radar_path[38, 1] := 525; radar_path[38, 2] := 325;
  radar_path[39, 1] := 525; radar_path[39, 2] := 425;
  radar_path[40, 1] := 25; radar_path[40, 2] := 125;
  radar_path[41, 1] := 25; radar_path[41, 2] := 25;
  radar_path[42, 1] := 25; radar_path[42, 2] := 25;
  
  points_snake1[1, 1]:=25;  points_snake1[1 ,2]:=25;
  points_snake1[2, 1]:=525; points_snake1[2 ,2]:=25;
  points_snake1[3, 1]:=525; points_snake1[3 ,2]:=75;
  points_snake1[4, 1]:=25;  points_snake1[4 ,2]:=75;
  points_snake1[5, 1]:=25;  points_snake1[5 ,2]:=125;
  points_snake1[6, 1]:=525; points_snake1[6 ,2]:=125;
  points_snake1[7, 1]:=525; points_snake1[7 ,2]:=175;
  points_snake1[8, 1]:=25;  points_snake1[8 ,2]:=175;
  points_snake1[9, 1]:=25;  points_snake1[9 ,2]:=225;
  points_snake1[10,1]:=525; points_snake1[10,2]:=225;
  points_snake1[11,1]:=525; points_snake1[11,2]:=275;
  points_snake1[12,1]:=25;  points_snake1[12,2]:=275;
  points_snake1[13,1]:=25;  points_snake1[13,2]:=325;
  points_snake1[14,1]:=525; points_snake1[14,2]:=325;
  points_snake1[15,1]:=525; points_snake1[15,2]:=375;
  points_snake1[16,1]:=25;  points_snake1[16,2]:=375;
  points_snake1[17,1]:=25;  points_snake1[17,2]:=425;
  points_snake1[18,1]:=525; points_snake1[18,2]:=425;
  points_snake1[19,1]:=525; points_snake1[19,2]:=475;
  points_snake1[20,1]:=25;  points_snake1[20,2]:=475;
  points_snake1[21,1]:=25;  points_snake1[21,2]:=525;
  points_snake1[22,1]:=525; points_snake1[22,2]:=525;
  
  points_snake2[1, 1]:=25;   points_snake2[1 ,2]:=25;
  points_snake2[2, 1]:=525;  points_snake2[2 ,2]:=25;
  points_snake2[3, 1]:=525;  points_snake2[3 ,2]:=75;
  points_snake2[4, 1]:=25;   points_snake2[4 ,2]:=75;
  points_snake2[5, 1]:=25;   points_snake2[5 ,2]:=125;
  points_snake2[6, 1]:=525;  points_snake2[6 ,2]:=125;
  points_snake2[7, 1]:=525;  points_snake2[7 ,2]:=175;
  points_snake2[8, 1]:=25;   points_snake2[8 ,2]:=175;
  points_snake2[9, 1]:=25;   points_snake2[9 ,2]:=225;
  points_snake2[10,1]:=525;  points_snake2[10,2]:=225;
  points_snake2[11,1]:=525;  points_snake2[11,2]:=275;
  points_snake2[12,1]:=25;   points_snake2[12,2]:=275;
  points_snake2[13,1]:=25;   points_snake2[13,2]:=325;
  points_snake2[14,1]:=525;  points_snake2[14,2]:=325;
  points_snake2[15,1]:=525;  points_snake2[15,2]:=375;
  points_snake2[16,1]:=25;   points_snake2[16,2]:=375;
  points_snake2[17,1]:=25;   points_snake2[17,2]:=425;
  points_snake2[18,1]:=525;  points_snake2[18,2]:=425;
  points_snake2[19,1]:=525;  points_snake2[19,2]:=475;
  points_snake2[20,1]:=25;   points_snake2[20,2]:=475;
  points_snake2[21,1]:=25;   points_snake2[21,2]:=525;
  points_snake2[22,1]:=525;  points_snake2[22,2]:=525; //1 круг
  points_snake2[23,1]:=25;   points_snake2[23,2]:=525;
  points_snake2[24,1]:=25;   points_snake2[24,2]:=475;
  points_snake2[25,1]:=525;  points_snake2[25,2]:=475;
  points_snake2[26,1]:=525;  points_snake2[26,2]:=425;
  points_snake2[27,1]:=25;   points_snake2[27,2]:=425;
  points_snake2[28,1]:=25;   points_snake2[28,2]:=375;
  points_snake2[29,1]:=525;  points_snake2[29,2]:=375;
  points_snake2[30,1]:=525;  points_snake2[30,2]:=325;
  points_snake2[31,1]:=25;   points_snake2[31,2]:=325;
  points_snake2[32,1]:=25;   points_snake2[32,2]:=275;
  points_snake2[33,1]:=525;  points_snake2[33,2]:=275;
  points_snake2[34,1]:=525;  points_snake2[34,2]:=225;
  points_snake2[35, 1]:=25;  points_snake2[35 ,2]:=225;
  points_snake2[36, 1]:=25;  points_snake2[36 ,2]:=175;
  points_snake2[37, 1]:=525; points_snake2[37 ,2]:=175;
  points_snake2[38, 1]:=525; points_snake2[38 ,2]:=125;
  points_snake2[39, 1]:=25;  points_snake2[39 ,2]:=125;
  points_snake2[40, 1]:=25;  points_snake2[40 ,2]:=75;
  points_snake2[41, 1]:=525; points_snake2[41 ,2]:=75;
  points_snake2[42, 1]:=525; points_snake2[42 ,2]:=25;
  points_snake2[43, 1]:=25;  points_snake2[43 ,2]:=25;
  
  points_spiral1[1, 1]:=275; points_spiral1[1 ,2]:=275;
  points_spiral1[2, 1]:=225; points_spiral1[2 ,2]:=275;
  points_spiral1[3, 1]:=225; points_spiral1[3 ,2]:=225;
  points_spiral1[4, 1]:=325; points_spiral1[4 ,2]:=225;
  points_spiral1[5, 1]:=325; points_spiral1[5 ,2]:=325;
  points_spiral1[6, 1]:=175; points_spiral1[6 ,2]:=325;
  points_spiral1[7, 1]:=175; points_spiral1[7 ,2]:=175;
  points_spiral1[8, 1]:=375; points_spiral1[8 ,2]:=175;
  points_spiral1[9, 1]:=375; points_spiral1[9 ,2]:=375;
  points_spiral1[10,1]:=125; points_spiral1[10,2]:=375;
  points_spiral1[11,1]:=125; points_spiral1[11,2]:=125;
  points_spiral1[12,1]:=425; points_spiral1[12,2]:=125;
  points_spiral1[13,1]:=425; points_spiral1[13,2]:=425;
  points_spiral1[14,1]:=75;  points_spiral1[14,2]:=425;
  points_spiral1[15,1]:=75;  points_spiral1[15,2]:=75;
  points_spiral1[16,1]:=475; points_spiral1[16,2]:=75;
  points_spiral1[17,1]:=475; points_spiral1[17,2]:=475;
  points_spiral1[18,1]:=25;  points_spiral1[18,2]:=475;
  points_spiral1[19,1]:=25;  points_spiral1[19,2]:=25;
  points_spiral1[20,1]:=525; points_spiral1[20,2]:=25;
  points_spiral1[21,1]:=525; points_spiral1[21,2]:=525;
  points_spiral1[22,1]:=25;  points_spiral1[22,2]:=525;
  
  points_spiral2[1, 1]:=275; points_spiral2[1 ,2]:=275;
  points_spiral2[2, 1]:=225; points_spiral2[2 ,2]:=275;
  points_spiral2[3, 1]:=225; points_spiral2[3 ,2]:=225;
  points_spiral2[4, 1]:=325; points_spiral2[4 ,2]:=225;
  points_spiral2[5, 1]:=325; points_spiral2[5 ,2]:=325;
  points_spiral2[6, 1]:=175; points_spiral2[6 ,2]:=325;
  points_spiral2[7, 1]:=175; points_spiral2[7 ,2]:=175;
  points_spiral2[8, 1]:=375; points_spiral2[8 ,2]:=175;
  points_spiral2[9, 1]:=375; points_spiral2[9 ,2]:=375;
  points_spiral2[10,1]:=125; points_spiral2[10,2]:=375;
  points_spiral2[11,1]:=125; points_spiral2[11,2]:=125;
  points_spiral2[12,1]:=425; points_spiral2[12,2]:=125;
  points_spiral2[13,1]:=425; points_spiral2[13,2]:=425;
  points_spiral2[14,1]:=75;  points_spiral2[14,2]:=425;
  points_spiral2[15,1]:=75;  points_spiral2[15,2]:=75;
  points_spiral2[16,1]:=475; points_spiral2[16,2]:=75;
  points_spiral2[17,1]:=475; points_spiral2[17,2]:=475;
  points_spiral2[18,1]:=25;  points_spiral2[18,2]:=475;
  points_spiral2[19,1]:=25;  points_spiral2[19,2]:=25;
  points_spiral2[20,1]:=525; points_spiral2[20,2]:=25;
  points_spiral2[21,1]:=525; points_spiral2[21,2]:=525;
  points_spiral2[22,1]:=25;  points_spiral2[22,2]:=525; //круг
  points_spiral2[43,1]:=275; points_spiral2[43,2]:=275;
  points_spiral2[42,1]:=225; points_spiral2[42,2]:=275;
  points_spiral2[41,1]:=225; points_spiral2[41,2]:=225;
  points_spiral2[40,1]:=325; points_spiral2[40,2]:=225;
  points_spiral2[39,1]:=325; points_spiral2[39,2]:=325;
  points_spiral2[38,1]:=175; points_spiral2[38,2]:=325;
  points_spiral2[37,1]:=175; points_spiral2[37,2]:=175;
  points_spiral2[36,1]:=375; points_spiral2[36,2]:=175;
  points_spiral2[35,1]:=375; points_spiral2[35,2]:=375;
  points_spiral2[34,1]:=125; points_spiral2[34,2]:=375;
  points_spiral2[33,1]:=125; points_spiral2[33,2]:=125;
  points_spiral2[32,1]:=425; points_spiral2[32,2]:=125;
  points_spiral2[31,1]:=425; points_spiral2[31,2]:=425;
  points_spiral2[30,1]:=75;  points_spiral2[30,2]:=425;
  points_spiral2[29,1]:=75;  points_spiral2[29,2]:=75;
  points_spiral2[28,1]:=475; points_spiral2[28,2]:=75;
  points_spiral2[27,1]:=475; points_spiral2[27,2]:=475;
  points_spiral2[26,1]:=25;  points_spiral2[26,2]:=475;
  points_spiral2[25,1]:=25;  points_spiral2[25,2]:=25;
  points_spiral2[24,1]:=525; points_spiral2[24,2]:=25;
  points_spiral2[23,1]:=525; points_spiral2[23,2]:=525;
  points_spiral2[44,1]:=275; points_spiral2[44,2]:=275;
end;

procedure Show_static; // Появление статической картинки
begin
  SetWindowSize(1350, 750);;
  CenterWindow;
  clearwindow(clWhite);
  render;
  SetPenColor(clBlack);
   // Угловое поле
  SetPenWidth(1);
  SetPenColor(clgreen);
  SetPenStyle(psSolid);
  pos_y := 25;  pos_x := 25;
  Line(50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25) + 25, 50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25) + 25);
  Line(50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25) + 25, 50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25) - 24);
  Line(50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25) - 24, 50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25) - 24);
  Line(50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25) - 24, 50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25) + 25);
  SetPenColor(clBlack);
  //line(950, 300, 375, 500);   line(950, 300, 375, 100); // линии поля обзора
  Line(50 + (round(pos_x - 25)), (round(pos_y)) + get_y(pos_x - 25), 50 + (round(pos_x + 25)), (round(pos_y)) + get_y(pos_x + 25));       // Центр. линии
  Line(50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) + 28, 50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) - 24);   
  SetPenColor(clgreen); arc(750, 270, 80, 135, 180);   line(675, 245, 665, 255);   line(675, 245, 678, 258);   line(680, 232, 680, 220);  line(680, 232, 692, 227);   textout(670, 260, '2Wок');
  line(50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) + 28, 900, 300);   line(50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) - 24, 900, 300);   line(50 + (round(pos_x)), (round(pos_y)) + get_y(pos_x + 25) + 3, 900, 300);  line(400, 162, 445, 182); line(400, 162, 450, 170); textout(460, 170, 'Xок'); 
  SetPenColor(clBlack);
  SetPenWidth(3);   
  SetPenColor(clRed);   
  DrawCircle(175, 460, 2); // Цель 
  SetPenWidth(1);  
  SetPenColor(clBlack);  
  textout(50, 5, '      Угловое поле ОК');    SetBrushColor(clGreen);  line(120, 25, 75, 70);  circle(75, 70, 5);   SetBrushColor(clWhite);  
  textout(150, 600, '      Поле обзора');   SetBrushColor(clBlack);  line(200, 600, 250, 500);  circle(250, 500, 5);   SetBrushColor(clWhite);  
  textout(60, 620, '      Цель');   SetBrushColor(clRed);  line(100, 620, 175, 460);  circle(175, 460, 5);   SetBrushColor(clWhite);  
  line(1150, 330, 1130, 275);        // Ключ 1
  arc(1150, 320, 20, 85, 155);   line(1132, 312, 1142, 307);   line(1132, 312, 1132, 302);   line(1154, 300, 1146, 306);  line(1154, 300, 1147, 295);
  line(1150, 330, 1170, 275);        // Ключ 2
  arc(1150, 330, 20, 90, 30);   line(1170, 322, 1160, 319);   line(1170, 322, 1165, 310);
  textout(450, 670, '      Нажмите кнопку "Enter" для продолжения');
  SetPenColor(clBlack);
  // Обозначения
  textout(750, 540, '      ОК - оптический координатор в 2-х осном подвесе;');
  textout(750, 560, '      ДСП - датчик сигнала поиска цели;');
  textout(750, 580, '      ПРР - переключатель режима работы пеленгатора;');
  textout(750, 600, '      ПрОК - привод оптического координатора;');
  textout(750, 620, '      ИУРок - индикатор углов разворота оптического координатора.');
  textout(750, 640, '      СУ - система управления.');
  // координаты вершин
  textout(5, 55, '(50,50)');     // ЛВТ
  textout(610, 5, '(600,0)');     // ПВТ
  textout(5, 610, '(50,600)');     // ЛНТ
  textout(610, 560, '(600,550)');     // ПНТ
  textout(335, 270, '(325,300)');     // ЦТ
  SetBrushColor(clBlue); circle(50,50,5); circle(600,3,5); circle(50,600,5);  circle(600,550,5); circle(325,300,5);  SetBrushColor(clWhite);  // Жирные точки вершин
  SetPenWidth(1);
  SetPenColor(clgreen);
  SetPenStyle(psSolid);
  redraw;
  readln;
end;

procedure Show_Zm;
begin
target_status:=0;
  turn_p:=0;
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  pos_y := 25;
  to_left := false;
  while (pos_y <= 525) do 
  begin
	turn_p:=turn_p+1;
	if (to_left = true) then begin
	  pos_x := 525;
	  while (pos_x > 0) do begin
		render;
		DrawKursor;  
		pos_x := pos_x - 50;
		SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		grafik;
		redraw;
		readln;
	  end;
	  to_left := false;
	turn_p:=turn_p+1;
	end
	else begin
	  pos_x := 25;
	  while (pos_x <= 525) do begin
		render;
		DrawKursor; 
		pos_x := pos_x + 50;
		grafik;
		SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		redraw;
		readln;
	  end;
	  to_left := true;
	  turn_p:=turn_p+1;
	end;
	pos_y := pos_y + 50;
  end;
  
  if (bp=22) then begin
  turn_p:=turn_p-1;
  pos_y := pos_y - 50;
  to_left := true;
	while (pos_y >= 25) do 
	begin
	turn_p:=turn_p+1;
	  if (to_left = true) then begin
		pos_x := 525;
		while (pos_x > 0) do begin
		  render;
		  DrawKursor;  
		  pos_x := pos_x - 50;
		  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		  grafik;
		  redraw;
		  readln;
		end;
		to_left := false;
		turn_p:=turn_p+1;
	  end
	  else begin
		pos_x := 25;
		while (pos_x < 525) do begin
		  render;
		  DrawKursor; 
		  pos_x := pos_x + 50;
		  grafik;
		  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		  redraw;
		  readln;
		end;
		to_left := true;
		turn_p:=turn_p+1;
	  end;
	  pos_y := pos_y - 50;
	end;
  end;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln();
end;

procedure Show_Zm_Target;
label ret, nech, ch;
begin
  SetWindowSize(1350, 750);
  ret:
  if (num_proch >= number_target_status) then begin render;
	  DrawKursor;
	  stat(0);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  redraw; 
  readln; exit; 
  end;
  target_status := 0;
  col_points := 0;
  CenterWindow;
  clearwindow;
  if ((bp=32) and (num_proch mod 2 = 1)) then goto nech;
  turn_p:=0;
  pos_y := 25;
  to_left := false;
  while (pos_y <= 525) do begin
  turn_p:=turn_p+1;
	if (target_status = 1) then break;
	if (to_left = true) then begin
	  pos_x := 525;
	  while (pos_x > 0) do begin
		if (target_status = 1) then begin
		  pos_x := pos_x + 50;
		  pos_y:=pos_y-50;
		  break;
		end;
		render;
		target_move(false);
		DrawKursor;
		SetPenColor(clBlue); 
		SetPenWidth(1);
		if (col_points >= 2) then for var i := 1 to col_points - 1 do Line(50 + (round(path[1, i])),  (round(path[2, i])) + get_y(path[1, i]),  50 + (round(path[1, i + 1])),   (round(path[2, i + 1])) + get_y(path[1, i + 1]));
		SetPenColor(clRed); 
		SetPenWidth(3);
		DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
		SetPenWidth(1);  
		SetPenColor(clgreen);  // Цель
		pos_x := pos_x - 50;
		SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		grafik;
		if (target_status=-1) then begin 
		  lost_target; 
		  Show_Zm_Target;
		  exit; 
		end;
		stat(1.0/121.0);
		redraw;
		readln;
	  end;
	  to_left := false;
	  turn_p:=turn_p+1;
	end
	else begin
	  pos_x := 25;
	  while (pos_x < 535) do 
	  begin
		if (target_status = 1) then begin
		  pos_x := pos_x - 50;
		  pos_y:=pos_y-50;
		  break;
		end;
		render;
		target_move(false);
		DrawKursor; 
		SetPenWidth(1);   
		SetPenColor(clBlue); 
		if (col_points >= 2) then begin
		  for var i := 1 to col_points - 1 do 
			Line(50 + (round(path[1, i])),  (round(path[2, i])) + get_y(path[1, i]),  50 + (round(path[1, i + 1])),   (round(path[2, i + 1])) + get_y(path[1, i + 1]));
		end;
		SetPenColor(clRed); 
		SetPenWidth(3);
		DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
		SetPenWidth(1);  
		SetPenColor(clgreen);  // Цель
		pos_x := pos_x + 50;
		SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		grafik;
		if (target_status=-1) then begin 
		  lost_target; 
		  Show_Zm_Target;
		  exit; 
		end;
		stat(1.0/121.0);
		readln;
	  end;
	  to_left := true;
	  turn_p:=turn_p+1;
	end;
	pos_y := pos_y + 50;
  end;
  goto ch;
  nech:
  turn_p:=22;
  col_points := 0;
  if ((bp=32) and (target_status = 0) and (num_proch mod 2 = 1)) then begin
  //lost_target;
	turn_p:=turn_p-1;
	pos_y := 525;
	to_left := true;
	while (pos_y >= 25) do begin
	turn_p:=turn_p+1;
	  if (target_status = 1) then break;
	  if (to_left = true) then begin
		pos_x := 525;
		while (pos_x > 0) do 
		begin
		  if (target_status = 1) then begin
			pos_x := pos_x + 50;
			  pos_y:=pos_y+50;
			break;
		  end;
		  render;
		  target_move(false);
		  DrawKursor;  
		  SetPenColor(clBlue); 
		  SetPenWidth(1);
		  if (col_points >= 2) then begin
			for var i := 1 to col_points - 1 do 
			  Line(50 + (round(path[1, i])),  (round(path[2, i])) + get_y(path[1, i]),  50 + (round(path[1, i + 1])),   (round(path[2, i + 1])) + get_y(path[1, i + 1]));
		  end;
		  SetPenColor(clRed); 
		  SetPenWidth(3);
		  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
		  SetPenWidth(1);  
		  SetPenColor(clgreen);  // Цель
		  pos_x := pos_x - 50;
		  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		  grafik;
		  if (target_status=-1) then begin 
			lost_target; 
			Show_Zm_Target;
			exit; 
		  end;
		  stat(1.0/121.0);
		  readln;
		end;
		to_left := false;
		turn_p:=turn_p+1;
	  end
	  else begin
		pos_x := 25;
		while (pos_x < 535) do begin
		  if (target_status = 1) then begin
			pos_x := pos_x - 50;
			pos_y:=pos_y+50;
			break;
		  end;
		  render;
		  target_move(false);
		  DrawKursor; 
		  SetPenWidth(1);   
		  SetPenColor(clBlue); 
		  if (col_points >= 2) then begin
			for var i := 1 to col_points - 1 do 
			  Line(50 + (round(path[1, i])),  (round(path[2, i])) + get_y(path[1, i]),  50 + (round(path[1, i + 1])),   (round(path[2, i + 1])) + get_y(path[1, i + 1]));
		  end;
		  SetPenColor(clRed); 
		  SetPenWidth(3);
		  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
		  SetPenWidth(1);  
		  SetPenColor(clgreen);  // Цель
		  pos_x := pos_x + 50;
		  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
		  grafik;
		  if (target_status=-1) then begin 
			lost_target; 
			Show_Zm_Target;
			exit; 
		  end;
		  stat(1.0/121.0);
		  readln;
		end;
		to_left := true;
		turn_p:=turn_p+1;
	  end;
	  pos_y := pos_y - 50;
	end;
  end;
  ch:
  if (target_status = 0) then begin 
  lost_target;
	goto ret;
	end;
  zaxvat;
  if (num_proch < number_target_status) then Show_Zm_Target else begin
	
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
	grafik;
	redraw;
	readln();
  end;
end;

procedure Show_Spiral_razv;
begin
target_status:=0;
  turn_p:=1;
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  pos_y := 275;
  pos_x := 275;
  to_left := false;
  Col_step := 1;
  moving := Left;
  step_dx := -50;
  step_dy := 0; 
  render;
  DrawKursor;
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln;
  spiral_end := false;
  while (spiral_end = false) do begin
	for var i := 1 to Col_step do begin
	  pos_x := pos_x + step_dx;
	  pos_y := pos_y + step_dy;
	  render;
	  DrawKursor;
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
	  grafik;
	  redraw;
	  readln;
	  if ((pos_x = 25) and (pos_y = 525)) then begin
		spiral_end := true;
		break;
	  end;
	end;
	Turn(true);
  end;
  
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln();
end;

procedure Show_Spiral_svor;
begin
target_status:=0;
  turn_p:=0;
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  pos_x := points_spiral2[1, 1];
  pos_y := points_spiral2[1, 2];
  for var i := 1 to 43 do 
  begin
  turn_p:=turn_p+1;
	radar_step_x := round(abs(points_spiral2[i, 1] - points_spiral2[i + 1, 1]) / 50); //сколько шагов по X в текущей итерации
	radar_step_y := round(abs(points_spiral2[i, 2] - points_spiral2[i + 1, 2]) / 50); //сколько шагов по Y в текущей итерации
	radar_dx := (points_spiral2[i + 1, 1] - points_spiral2[i, 1]) / getmax; 
	radar_dy := (points_spiral2[i + 1, 2] - points_spiral2[i, 2]) / getmax; 
	for var  radar_x := 1 to getmax do 
	begin
	  render;
	  DrawKursor; 
	  grafik;
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
	  redraw;
	  pos_x := pos_x + radar_dx;
	  pos_y := pos_y + radar_dy;
	  readln;
	end;
  end;
  render;
  DrawKursor; 
  grafik;
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln();
end;

procedure Show_Spiral_razv_target;
label ret;
begin
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  ret:
  if (num_proch >= number_target_status) then begin render;
	  DrawKursor;
	
	  stat(0);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  redraw;
  readln; exit; 
  end;
  target_status := 0;
  col_points := 0;
  turn_p:=1;
  pos_y := 275;
  pos_x := 275;
  to_left := false;
  Col_step := 1;
  moving := Left;
  step_dx := -50;
  step_dy := 0; 
  render;
  DrawKursor;
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln;
  spiral_end := false;
  while (spiral_end = false) do begin
	if (target_status = 1) then break;
	for var k := 1 to Col_step do begin
	  render;
	  DrawKursor;
	  target_move(true);
	  pos_x := pos_x + step_dx;
	  pos_y := pos_y + step_dy;
	  SetPenWidth(1);   
	  SetPenColor(clBlue); 
	  if (col_points >= 2) then begin
		for var i := 1 to col_points - 1 do 
		  Line(50 + (round(path[1, i])),  (round(path[2, i])) + get_y(path[1, i]),  50 + (round(path[1, i + 1])),   (round(path[2, i + 1])) + get_y(path[1, i + 1]));
	  end;
	  SetPenColor(clRed); 
	  SetPenWidth(3);
	  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	  SetPenWidth(1);  
	  SetPenColor(clgreen);  // Цель
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
	  grafik;
	  if (target_status=-1) then begin 
		lost_target; 
		Show_Spiral_razv_target;
		exit; 
	  end;
	  stat(1.0/121.0);
	  redraw;
	  readln;
	  if (target_status=1) then begin
		pos_x:=pos_x-step_dx;
		pos_y:=pos_y-step_dy;
		spiral_end := true;
		break;
	  end;
	  if ((pos_x = 25) and (pos_y = 525)) then begin
		spiral_end := true;
		break;
	  end;
	end;
	Turn(true);
  end;
	  render;
  DrawKursor;//дорисовать последний шаг
  redraw;//дорисовать последний шаг
  readln;
  if (target_status = 0) then begin
  lost_target; goto ret; end;
  zaxvat;
  if (num_proch < number_target_status) then Show_Spiral_razv_target else begin
	
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
	grafik;
	redraw;
	readln();
  end;
end;

procedure Show_Spiral_svor_target;
label ret;
var nn,kk:integer;
begin
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  ret:
  if (num_proch >= number_target_status) then begin render;
	  DrawKursor;
	
	  stat(0);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  redraw;
  readln; exit; 
  end;
  target_status := 0;
  col_points := 0;
  turn_p:=0;
  pos_x := points_spiral2[1, 1];
  pos_y := points_spiral2[1, 2];
  if (num_proch mod 2 = 1) then begin 
  nn:=22; kk:=43; 
  pos_x := points_spiral2[22, 1];
  pos_y := points_spiral2[22, 2];
  turn_p:=21;
  end 
  else begin nn:=1; kk:=21; end;
  for var i := nn to kk do 
  begin
  turn_p:=turn_p+1;
	if (target_status = 1) then break;
	radar_step_x := round(abs(points_spiral2[i, 1] - points_spiral2[i + 1, 1]) / 50); //сколько шагов по X в текущей итерации
	radar_step_y := round(abs(points_spiral2[i, 2] - points_spiral2[i + 1, 2]) / 50); //сколько шагов по Y в текущей итерации
	radar_dx := (points_spiral2[i + 1, 1] - points_spiral2[i, 1]) / getmax; 
	radar_dy := (points_spiral2[i + 1, 2] - points_spiral2[i, 2]) / getmax; 
	for var radar_x := 1 to getmax do 
	begin
	  render;
	  DrawKursor;
	  target_move(false);
	  SetPenColor(clBlue); 
	  SetPenWidth(1);
	  if (col_points >= 2) then begin
		for var radar_y := 1 to col_points - 1 do 
		  Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	  end;
	  SetPenColor(clRed); 
	  SetPenWidth(3);
	  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	  SetPenWidth(1);  
	  SetPenColor(clgreen);  // Цель
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	  grafik;
	  if (target_status=-1) then begin 
		lost_target; 
		Show_Spiral_svor_target;
		exit; 
	  end;
	  stat(1.0/121.0);
	  redraw;
	  if (target_status = 1) then break;
	  pos_x := pos_x + radar_dx;
	  pos_y := pos_y + radar_dy;
	  readln;
	end;
  end;
	render;
	  DrawKursor;
	target_move(false);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  if (target_status = 0) then begin lost_target; goto ret; end;
  zaxvat;
  if (num_proch < number_target_status) then Show_Spiral_svor_target else begin
  
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
	grafik;
	redraw;
	readln();
  end;
end;

procedure Show_Radar;
begin
target_status:=0;
  turn_p:=0;
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  pos_x := radar_path[1, 1];
  pos_y := radar_path[1, 2];
  for var i := 1 to 41 do 
  begin
  turn_p:=turn_p+1;
	radar_step_x := round(abs(radar_path[i, 1] - radar_path[i + 1, 1]) / 50); //сколько шагов по X в текущей итерации
	radar_step_y := round(abs(radar_path[i, 2] - radar_path[i + 1, 2]) / 50); //сколько шагов по Y в текущей итерации
	radar_dx := (radar_path[i + 1, 1] - radar_path[i, 1]) / getmax; 
	radar_dy := (radar_path[i + 1, 2] - radar_path[i, 2]) / getmax; 
	if (((radar_step_x = 1) and (radar_step_y = 0)) or ((radar_step_y = 1) and (radar_step_x = 0))) then begin
	  if (radar_step_x = 1) then begin
		radar_dx := 50 * (abs(radar_path[i, 1] - radar_path[i + 1, 1]) / (radar_path[i, 1] - radar_path[i + 1, 1])); radar_dy := 0;
	  end
	  else begin
		radar_dx := 0; radar_dy := 50 * (abs(radar_path[i, 2] - radar_path[i + 1, 2]) / (radar_path[i, 2] - radar_path[i + 1, 2]));
	  end; 
	end;
	for var  radar_x := 1 to getmax do 
	begin
	  render;
	  DrawKursor; 
	  grafik;
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
	  redraw;
	  pos_x := pos_x + radar_dx;
	  pos_y := pos_y + radar_dy;
	  readln;
	end;
  end;
  render;
  DrawKursor; 
  grafik;
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln();
end;

procedure Show_Radar2;
begin
target_status:=0;
  turn_p:=0;
  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  pos_x := radar_path[1, 1];
  pos_y := radar_path[1, 2];
  for var i := 1 to 21 do 
  begin
  turn_p:=turn_p+1;
	radar_step_x := round(abs(radar_path[i, 1] - radar_path[i + 1, 1]) / 50); //сколько шагов по X в текущей итерации
	radar_step_y := round(abs(radar_path[i, 2] - radar_path[i + 1, 2]) / 50); //сколько шагов по Y в текущей итерации
	radar_dx := (radar_path[i + 1, 1] - radar_path[i, 1]) / getmax; 
	radar_dy := (radar_path[i + 1, 2] - radar_path[i, 2]) / getmax; 
	if (((radar_step_x = 1) and (radar_step_y = 0)) or ((radar_step_y = 1) and (radar_step_x = 0))) then begin
	  if (radar_step_x = 1) then begin
		radar_dx := 50 * (abs(radar_path[i, 1] - radar_path[i + 1, 1]) / (radar_path[i, 1] - radar_path[i + 1, 1])); radar_dy := 0;
	  end
	  else begin
		radar_dx := 0; radar_dy := 50 * (abs(radar_path[i, 2] - radar_path[i + 1, 2]) / (radar_path[i, 2] - radar_path[i + 1, 2]));
	  end; 
	end;
	for var  radar_x := 1 to getmax do 
	begin
	  render;
	  DrawKursor; 
	  grafik;
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
	  redraw;
	  if (i=21) then break;
	  pos_x := pos_x + radar_dx;
	  pos_y := pos_y + radar_dy;
	  readln;
	end;
  end;
  render;
  DrawKursor; 
  grafik;
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ
  grafik;
  redraw;
  readln();
end;

procedure Show_Radar_target2;
label ret;
var nn,kk:integer;
begin

  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  ret:
  if (num_proch >= number_target_status) then begin render;
	  DrawKursor;
	
	  stat(0);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  redraw;
  readln; exit; 
  end;
  target_status := 0;
  col_points := 0;
  turn_p:=0;
  pos_x := radar_path[1, 1];
  pos_y := radar_path[1, 2];
  for var i := 1 to 21 do 
  begin
  turn_p:=turn_p+1;
	if (target_status = 1) then break;
	radar_step_x := round(abs(radar_path[i, 1] - radar_path[i + 1, 1]) / 50); //сколько шагов по X в текущей итерации
	radar_step_y := round(abs(radar_path[i, 2] - radar_path[i + 1, 2]) / 50); //сколько шагов по Y в текущей итерации
	radar_dx := (radar_path[i + 1, 1] - radar_path[i, 1]) / getmax; 
	radar_dy := (radar_path[i + 1, 2] - radar_path[i, 2]) / getmax; 
	if (((radar_step_x = 1) and (radar_step_y = 0)) or ((radar_step_y = 1) and (radar_step_x = 0))) then begin
	  if (radar_step_x = 1) then begin
		radar_dx := 50 * (abs(radar_path[i, 1] - radar_path[i + 1, 1]) / (radar_path[i, 1] - radar_path[i + 1, 1])); radar_dy := 0;
	  end
	  else begin
		radar_dx := 0; radar_dy := 50 * (abs(radar_path[i, 2] - radar_path[i + 1, 2]) / (radar_path[i, 2] - radar_path[i + 1, 2]));
	  end; 
	end;
	for var radar_x := 1 to getmax do 
	begin
	  render;
	  DrawKursor;
	  target_move(false);
	  SetPenColor(clBlue); 
	  SetPenWidth(1);
	  if (col_points >= 2) then begin
		for var radar_y := 1 to col_points - 1 do 
		  Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	  end;
	  SetPenColor(clRed); 
	  SetPenWidth(3);
	  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	  SetPenWidth(1);  
	  SetPenColor(clgreen);  // Цель
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	  grafik;
	  if (target_status=-1) then begin 
		lost_target; 
		Show_Radar_target2;
		exit; 
	  end;
	  stat(1.0/121.0);
	  redraw;
	  if (target_status = 1) then break;
	  if (i=21) then break;
	  pos_x := pos_x + radar_dx;
	  pos_y := pos_y + radar_dy;
	  readln;
	end;
  end;
  render;
  DrawKursor;
  target_move(false);
  if (target_status = 0) then begin lost_target; goto ret; end;
  zaxvat;
  if (num_proch < number_target_status) then Show_Radar_target2 else 
  begin
	SetFontSize(11);
	textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
	redraw;
	readln();
	SetFontSize(9);
  end;
end;

procedure Show_Radar_target;
label ret;
var nn,kk:integer;
begin

  SetWindowSize(1350, 750);
  CenterWindow;
  clearwindow;
  ret:
  if (num_proch >= number_target_status) then begin render;
	  DrawKursor;
	
	  stat(0);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
  redraw;
  readln; exit; 
  end;
  target_status := 0;
  col_points := 0;
  turn_p:=0;
  pos_x := radar_path[1, 1];
  pos_y := radar_path[1, 2];
  if (num_proch mod 2 = 1) then begin 
  nn:=21; kk:=41; 
  pos_x := radar_path[21, 1];
  pos_y := radar_path[21, 2];
  turn_p:=20;
  end 
  else begin nn:=1; kk:=20; end;
  for var i := nn to kk do 
  begin
  turn_p:=turn_p+1;
	if (target_status = 1) then break;
	radar_step_x := round(abs(radar_path[i, 1] - radar_path[i + 1, 1]) / 50); //сколько шагов по X в текущей итерации
	radar_step_y := round(abs(radar_path[i, 2] - radar_path[i + 1, 2]) / 50); //сколько шагов по Y в текущей итерации
	radar_dx := (radar_path[i + 1, 1] - radar_path[i, 1]) / getmax; 
	radar_dy := (radar_path[i + 1, 2] - radar_path[i, 2]) / getmax; 
	if (((radar_step_x = 1) and (radar_step_y = 0)) or ((radar_step_y = 1) and (radar_step_x = 0))) then begin
	  if (radar_step_x = 1) then begin
		radar_dx := 50 * (abs(radar_path[i, 1] - radar_path[i + 1, 1]) / (radar_path[i, 1] - radar_path[i + 1, 1])); radar_dy := 0;
	  end
	  else begin
		radar_dx := 0; radar_dy := 50 * (abs(radar_path[i, 2] - radar_path[i + 1, 2]) / (radar_path[i, 2] - radar_path[i + 1, 2]));
	  end; 
	end;
	for var radar_x := 1 to getmax do 
	begin
	  render;
	  DrawKursor;
	  target_move(false);
	  SetPenColor(clBlue); 
	  SetPenWidth(1);
	  if (col_points >= 2) then begin
		for var radar_y := 1 to col_points - 1 do 
		  Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	  end;
	  SetPenColor(clRed); 
	  SetPenWidth(3);
	  DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	  SetPenWidth(1);  
	  SetPenColor(clgreen);  // Цель
	  SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	  grafik;
	  if (target_status=-1) then begin 
		lost_target; 
		Show_Radar_target;
		exit; 
	  end;
	  stat(1.0/119.0);
	  redraw;
	  if (target_status = 1) then break;
	  pos_x := pos_x + radar_dx;
	  pos_y := pos_y + radar_dy;
	  readln;
	end;
  end;
	render;
	  DrawKursor;
	target_move(false);
	SetPenColor(clBlue); 
	SetPenWidth(1);
	if (col_points >= 2) then begin
	  for var radar_y := 1 to col_points - 1 do 
		Line(50 + (round(path[1, radar_y])),  (round(path[2, radar_y])) + get_y(path[1, radar_y]),  50 + (round(path[1, radar_y + 1])),   (round(path[2, radar_y + 1])) + get_y(path[1, radar_y + 1]));
	end;
	SetPenColor(clRed); 
	SetPenWidth(3);
	DrawCircle(50 + Round(target_x), (round(target_y)) + get_y(target_x), 2); //рисуем окружность по центру радиусом 10
	SetPenWidth(1);  
	SetPenColor(clgreen);  // Цель
	SetPenWidth(3);   SetPenColor(clRed);   line(1150, 330, 1150, 275);    SetPenWidth(1);   SetPenColor(clBlack);   // Ключ		
	grafik;
	redraw;
  if (target_status = 0) then begin lost_target; goto ret; end;
  zaxvat;
  if (num_proch < number_target_status) then Show_Radar_target else begin
	
  SetFontSize(11);
  textout(550, 690, '      Нажмите кнопку "Enter" для продолжения');
  SetFontSize(9);
	grafik;
	redraw;
	readln();
  end;
end;

begin
  randomize;
  set_pathes;
  LockDrawing;
  bp:=0;
  SetWindowCaption('Демонстрация и оценка эффективности процесса поиска и обнаружения цели оптическим пеленгатором.');
  SetWindowSize(1000, 600);
  CenterWindow;
  clearwindow;
  textout(190, 30, '                             Учебная программа                                ');
  textout(120, 50, '    Демонстрация и оценка эффективности процесса поиска и обнаружения цели ОП.        ');
  textout(200, 70, '                          Версия от 12.04.2019 г.                              ');
  textout(110, 110, '        Последовательность работы программы:                                  ');
  textout(110, 130, '  а) демонстрация функциональной схемы оптического пеленгатора поисково-следящего типа; ');
  textout(110, 150, '  б) демонстрация траектории развёртки поля обзора перемещающимся полем зрения ОК ');
  textout(110, 170, '     согласно 6-ти анализируемым её законам;                                    ');
  textout(110, 190, '  в) исследование эффективности поиска и обнаружения перемещающейся цели системой,');
  textout(110, 210, '     использующей соответствующий закон развёртки поля обзора угловым полем ОК.  ');
  textout(110, 240, '        Разработчики программы доцент Илюхин И.М. и студент Белокуров Е.А. ');
  textout(110, 260, '  желают Вам успешных исследований.'); 
  textout(200, 320, '      Нажмите кнопку "Enter" для продолжения');
  redraw;
  Readln;
  while (bp<>8) do begin
	clearwindow;
	NormalizeWindow;
	SetWindowSize(1000, 600);
	CenterWindow;
	clearwindow;
	num_proch:=-1;
	k:=-1;
	textout(50, 10,  ' Варианты продолжения работы - bp;:');
	textout(10, 70,  ' 1- демонстрация Функциональной схемы оптического пеленгатора поисково следящего типа.');
	textout(10, 110,  ' Демонстрация и оценка эффективности анализируемых законов развертки поля обзора :');
	textout(10, 130,  '21- демонстрация строчного закона развёртки с возвращением в исходную точку поля обзора;  ');
	textout(10, 150,  '22- демонстрация строчного закона развёртки с последовательной сменой точек начала и конца обзора;  ');
	textout(10, 170, ' 31- оценка эффективности строчного закона развёртки с возвращением в исходную точку поля обзора; ');
	textout(10, 190, ' 32- оценка эффективности строчного закона развёртки с последовательной сменой точек начала и конца обзора;');
	textout(10, 210, ' 41- демонстрация спирального закона развёртки с возвращением в исходную точку поля обзора; ');
	textout(10, 230, ' 42- демонстрация спирального закона развёртки с последовательной сменой точек начала и конца обзора;');
	textout(10, 250, ' 51- оценка эффективности спирального закона развёртки с возвращением в исходную точку поля обзора; ');  
	textout(10, 270, ' 52- оценка эффективности спирального закона развёртки с последовательной сменой точек начала и конца обзора;');
	textout(10, 290, ' 61- демонстрация секущего закона развёртки с возвращением в исходную точку поля обзора; ');
	textout(10, 310, ' 62- демонстрация секущего закона развёртки с последовательной сменой точек начала и конца обзора; ');
	textout(10, 330, ' 71- оценка эффективности секущего закона развёртки с возвращением в исходную точку поля обзора');
	textout(10, 350, ' 72- оценка эффективности секущего закона развёртки с последовательной сменой точек начала и конца обзора.');
	textout(10, 370, ' 8- завершить работу.');
	textout(10, 470, '    bp = '); 
	redraw;
	readln(bp);    textout(60, 130, (bp));
	redraw;
	if  bp = 1 then Show_static; 
	if  ((bp = 21) or (bp=22)) then Show_Zm;
	if  ((bp = 31) or (bp=32))  then begin 
		read_target;	
		Show_Zm_Target;   
	end;
	if  bp = 41 then Show_Spiral_razv;
	if  bp = 42 then Show_Spiral_svor;
	if  bp = 51 then begin 
		read_target;
		Show_Spiral_razv_target;
	end;
	if  bp = 52 then begin 
		read_target;
		Show_Spiral_svor_target;
	end;
	if  bp = 61 then Show_Radar2;   
	if  bp = 62 then Show_Radar;  
	if  bp = 71 then begin
	  read_target;
	  Show_Radar_target2; 
	end; 
	if  bp = 72 then begin
	  read_target;
	  Show_Radar_target; 
	end;
  end;
  clearwindow;
  SetWindowSize(800, 200);
  textout(150, 30, 'Доцент Илюхин И.М. и студент Белокуров Е.А. желают Вам успеха           ');
  textout(300, 50, '                                     в достижении отличных результатов! ');
  textout(230, 90, '        Нажмите "крестик" для полного завершения программы!          ');
  redraw;
  readln;
end.

