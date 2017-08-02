unit UnitMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.WebBrowser,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, UnitHttpClient,
  FMX.ScrollBox, FMX.Memo, System.RegularExpressions, LbRSA, Soap.EncdDecd, LbAsym,
  Web.HTTPApp, System.DateUtils, OpenSSL.RSAUtils;

type
  TForm1 = class(TForm)
    mmo1: TMemo;
    btn1: TButton;
    btn2: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
  private
    state: Integer;
    procedure TestBaiduLogin;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}



procedure TForm1.btn2Click(Sender: TObject);
var
  RSA: TLbRSA;
  MyBytes: TArray<Byte>;

begin
  RSA := TLbRSA.Create(nil);
  RSA.KeySize := TLbAsymKeySize.aks1024;
  MyBytes := DecodeBase64(mmo1.Text);
  RSA.PublicKey.Clear;
  RSA.PublicKey.Modulus.CopyBuffer(Mybytes[29], 128);
  RSA.PublicKey.Exponent.CopyBuffer(Mybytes[159], 3);
  mmo1.Text := RSA.EncryptString('lzx221017');
  RSA.Free;
end;

function GetTimeStamp() : string;
begin
  Result := IntToStr(DateTimeToUnix(Now));
end;

procedure TForm1.TestBaiduLogin();
var
  Http: TMyHttpClient;
  ResStr: string;
  Regex: TRegEx;
  Match: TMatch;
  Token: string;
  Key: string;
  PublicKey: string;
  Password: string;
  MyBytes: TArray<Byte>;
  { ----- }
  RSA: TLbRSA;
  PostData: TStringList;
  ExpBuf: array of Byte;

  RSAUtil :TRSAUtil;
  OutStream: TStringStream;
begin
  ShowMessage(GetTimeStamp());
  Http := TMyHttpClient.Create;
  Http.Get('http://www.baidu.com/');
  ResStr := Http.Get('https://passport.baidu.com/v2/api/?getapi&tpl=pp&apiver=v3&tt='
    + GetTimeStamp
    + '&class=login&gid=D263086-E5AE-4A17-99AC-14DCDF5AFC46'
    + '&logintype=basicLogin&callback=bd__cbs__jgbb6x');
  mmo1.Text := ResStr;
  Regex := TRegex.Create('token"\s*:\s*"(\w+)"');
  Match := Regex.Match(ResStr);
  if Match.Success then
    Token := Match.Groups.Item[1].value
  else
    raise Exception.Create('Cannot get token!');

  Http.Get('https://passport.baidu.com/v2/api/?loginhistory&token=' + Token + '&tpl=pp&apiver=v3&tt='
    + GetTimeStamp + '&gid=D263086-E5AE-4A17-99AC-14DCDF5AFC46&callback=bd__cbs__waz4it');

  Http.Get('https://passport.baidu.com/v2/api/?logincheck&token=' + Token + '&tpl=pp&apiver=v3&tt='
    + GetTimeStamp + '&sub_source=leadsetpwd&username='
   + HTTPEncode('主板的乐') + '&isphone=false&callback=bd__cbs__cbbfcv');

  ResStr := Http.Get('https://passport.baidu.com/v2/getpublickey?token=' + Token + '&tpl=pp&apiver=v3&tt='
    + GetTimeStamp + '&gid=D263086-E5AE-4A17-99AC-14DCDF5AFC46&callback=bd__cbs__6im7dp');
  Regex := TRegex.Create('"key"\s*:\s*''(\w+)''');
  Match := Regex.Match(ResStr);
  if Match.Success then
    Key := Match.Groups.Item[1].value
  else
    raise Exception.Create('Cannot get key!');

  Regex := TRegex.Create('"pubkey":''(.+?)''');
  Match := Regex.Match(ResStr);
  if Match.Success then
    PublicKey := Match.Groups.Item[1].value
  else
    raise Exception.Create('Cannot get public key');
  PublicKey := PublicKey.Replace('\n', #10);
  PublicKey := PublicKey.Replace('\', '');
  mmo1.Text := PublicKey;

  {
  Regex := TRegex.Create('KEY-----\s([\s\S]+?)\s-----', [roMultiLine] );

  Match := Regex.Match(PublicKey);
  if Match.Success then
    PublicKey := Match.Groups.Item[1].value;
  RSA := TLbRSA.Create(nil);
  RSA.Encoding := TEncoding.UTF8;
  RSA.KeySize := TLbAsymKeySize.aks1024;
  MyBytes := DecodeBase64(PublicKey);
  RSA.PublicKey.Clear;
  RSA.PublicKey.Modulus.CopyBuffer(Mybytes[29], 128);
  RSA.PublicKey.Exponent.CopyBuffer(Mybytes[159], 3);
  Password := RSA.EncryptString('*******');
  RSA.Free;          }
  RSAUtil := TRSAUtil.Create;
  RSAUtil.PublicKey.LoadFromStream(TStringStream.Create(PublicKey));
  OutStream := TStringStream.Create;

  RSAUtil.PublicEncrypt(TStringStream.Create('%^!@WD)^)*S'), OutStream);
  Password := EncodeBase64(@OutStream.Bytes[0], OutStream.Size);
  PostData := TStringList.Create;
  PostData.Add('staticpage=' + HTTPEncode('https://passport.baidu.com/static/passpc-account/html/v3Jump.html'));
  PostData.Add('charset=UTF-8');
  PostData.Add('token=' + Token);
  PostData.Add('tpl=pp&subpro=&apiver=v3&tt=' + GetTimeStamp + '&codestring=&safeflg=0');
  PostData.Add('u=' + HTTPEncode('https://passport.baidu.com/'));
  PostData.Add('isPhone=false&detect=1&gid=D263086-E5AE-4A17-99AC-14DCDF5AFC46&quick_user=0');
  PostData.Add('logintype=basicLogin&logLoginType=pc_loginBasic&idc=&loginmerge=true');
  PostData.Add('username=' + HTTPEncode('主板的乐'));
  PostData.Add('password=' + HTTPEncode(Password));
  PostData.Add('mem_pass=on');
  PostData.Add('rsakey=' + Key);
  PostData.Add('crypttype=12&ppui_logintime=5391&countrycode=&fp_uid=e6322b887f42c0e698b6314997a067c0');
  PostData.Add('fp_info=' + HTTPEncode('e6322b887f42c0e698b6314997a067c0002~~~ozooNCitFAY-'
    + '5AjI8A~_looNGitZFUWZ6ErZoE~iitZFUWZ6Ej0Ft_PoopNoo3xi0CDnykU8G8HDfnoDyjI8AjI7un-J9k~PukQDUdQ8'
    + '6nB8FHzXA7kPfkK8AmUDAYUNGsI8GtKJurd8ykK43mTJfLV8ns37k8H8GPkJ-HVXuHfNfdU8ymfXfchJuYkDyHQ8fLTD'
    + 'ynf8ykkXuHwX5r0NG7HPfnoDukkD9vSXAjI8GcKNA~VDfY-Dpd~D6n9XAeBvywWDydk237unfkkPynW0fkKPunWDfYB4G'
    + 'sU8hdyXAnz8Gt_wlobJlobQlobFlosHi0jVnykU8G8HDfnoDyjI8AjI7un-J9k~PukQDUdQ86nB85r0NG7HPfnoDukkD9'
    + '7YCun-PG7wNfrk4YsQJ97wNfrkFfYIXG8kvyrH8AjI7GwkNznINAcB85rvDzcINAcB827QNznV8AjI7fLWDAYIED0Robb'
    + 'vp02IpApsv~sqEbbb6bcpEsbEb3bsbbtbuGbbcsBjnbbbcb3bbptut3bEsbbwb3~Hbpbbbbbvbbbbqsb8WsEbEEbr7Blos'
    + 'KlosDlostlosrVoYAiv8AeVnnZ_vitPAjaDfLzDE__olosVozz1v7toyoobUlobLosp2ugEjlobSlobRlobmlob'));
  PostData.Add('dv=MDExAAoALAALAqMAHAAAAF00AAcCAASRkZGRCQIAIoeELy6_v7-_v57a2o7PgcaU1ZjHmMiby5Sn-'
    + 'KfUocOux7MHAgAEkZGRkQkCACSJiiMiYmJiYmJ8lpbCg82K2JnUi9SE14fY67Trm_qJ-o3ikPQNAgAdkZGPanImZyl'
    + 'uPH0wbzBgM2M8D1APfx5tHmkGdBANAgAdkZGHeWE1dDp9L24jfCNzIHAvHEMcbA1-DXoVZwMIAgAhiYpSU2xsbHiTx4'
    + 'bIj92c0Y7RgdKC3e6x7p7_jP-I55XxBwIABJGRkZENAgAdkZGDVEwYWRdQAkMOUQ5eDV0CMW4xQSBTIFc4Si4IAgAhi'
    + 'YoVFFVVVUW-6qvlovCx_KP8rP-v8MOcw7PSodKlyrjcCAIACZGVp6bn5-fpVggCAA2Vl6Ojg4ODiTdfOls_BwIABJGR'
    + 'kZEGAgAokZGRiYmJiYqKio38_Pz_aWlpbu7u7urS0tLVVVVVVra2trExMTEy0hMCACiRtbW13andrd7ky-SU9Yb1heqY'
    + '7MKgwajMuZf0m_bZr52yjeGO6YDuFwIAFZGRk5OD7Y76k_ySsprux7zVs5vEthYCACKwxK-fsYawiLuJvo20hLSBuIG4'
    + 'i72MuYm4jb6NtIS8i7mLFQIACJGRkM1XMhznBQIABJGRkZoBAgAGkZCQmRi2BAIABpOTkZKnnhACAAGRDQIAHZGRkOD4'
    + 'rO2j5Lb3uuW66rnptoXahfWU55TjjP6aDQIAHZGRm4-Xw4LMi9mY1YrVhdaG2eq16pr7iPuM45H1CAIACZGVz88mJiYr'
    + 'IQkCACSJigcGRUVFRUVXioren9GWxIXIl8iYy5vE96j3h-aV5pH-jOgMAgAjibi4uLinUQVECk0fXhNME0MQQB8scyxcP'
    + 'U49SiVXM0MwRyMHAgAEkZGRkQ');
  PostData.Add('callback=bd__cbs__6im7dp');
  Http.SetCookie('FP_UID', 'e6322b887f42c0e698b6314997a067c0');


  mmo1.Text := Http.Post('https://passport.baidu.com/v2/api/?login', PostData);
end;

procedure TForm1.btn1Click(Sender: TObject);
begin
  TestBaiduLogin;
end;
end.
