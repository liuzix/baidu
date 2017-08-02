unit UnitHttpClient;

interface

uses System.Net.HttpClient, System.Classes, System.Sysutils;

type
  TMyHttpClient = class
  public
    constructor Create;
    destructor Destroy; override;
    function Get (const Url: string) : string;
    function Post (const Url: string; const Params: TStringList) : string;
    function GetCookie(const Name: string) : string;
    procedure SetCookie (const Name: string; const Value: string);
  private
    Http : THTTPClient;
    function StreamToString (const Stream: TStream) : string;
  end;

implementation

constructor TMyHttpClient.Create;
begin
  inherited;
  Http := THTTPClient.Create;
end;

destructor TMyHttpClient.Destroy;
begin
  Http.Free;
  inherited;
end;

function TMyHttpClient.Get (const Url: string) : string;
begin
  Result := StreamToString(Http.Get(Url).ContentStream);
end;

function TMyHttpClient.Post (const Url: string; const Params: TStringList) : string;
var
  PostStr: string;
  PostStream: TStringStream;
  i: Integer;
begin
  PostStr := '';
  if Params.Count > 0 then
  begin
    PostStr := Params[0];
    for i := 1 to Params.Count - 1 do
    begin
      PostStr := PostStr + '&' + Params[i];
    end;
  end;
  PostStream := TStringStream.Create(PostStr);
  Http.ContentType := 'application/x-www-form-urlencoded';
  Result := StreamToString(Http.Post(Url, PostStream).ContentStream);
  PostStream.Free;
end;

function TMyHttpClient.StreamToString (const Stream: TStream) : string;
var
  Buffer: array of Byte;
begin
  if not Assigned(Stream) then
    raise Exception.Create('Stream not assigned!');
  SetLength(Buffer, Stream.Size);
  Stream.Read(Buffer[0], Stream.Size);
  Result := TEncoding.ANSI.GetString(Buffer);
end;

function TMyHttpClient.GetCookie(const Name: string) : string;
var
  Cookie: TCookie;
begin
  for Cookie in Http.CookieManager.Cookies do
  begin
    if Cookie.Name = Name then
    begin
      Result := Cookie.Value;
      Exit;
    end;
  end;
  raise Exception.Create('Cookie ' + Name + ' not found');
end;

procedure TMyHttpClient.SetCookie (const Name: string; const Value: string);
begin
  Http.CookieManager.AddServerCookie(Name + '=' + Value, 'https://baidu.com');
end;

end.
