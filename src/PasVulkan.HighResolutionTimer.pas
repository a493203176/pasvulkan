(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                   Version see PasVulkan.RandomGenerator.pas                *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2019, Benjamin Rosseaux (benjamin@rosseaux.de)          *
 *                                                                            *
 * This software is provided 'as-is', without any express or implied          *
 * warranty. In no event will the authors be held liable for any damages      *
 * arising from the use of this software.                                     *
 *                                                                            *
 * Permission is granted to anyone to use this software for any purpose,      *
 * including commercial applications, and to alter it and redistribute it     *
 * freely, subject to the following restrictions:                             *
 *                                                                            *
 * 1. The origin of this software must not be misrepresented; you must not    *
 *    claim that you wrote the original software. If you use this software    *
 *    in a product, an acknowledgement in the product documentation would be  *
 *    appreciated but is not required.                                        *
 * 2. Altered source versions must be plainly marked as such, and must not be *
 *    misrepresented as being the original software.                          *
 * 3. This notice may not be removed or altered from any source distribution. *
 *                                                                            *
 ******************************************************************************
 *                  General guidelines for code contributors                  *
 *============================================================================*
 *                                                                            *
 * 1. Make sure you are legally allowed to make a contribution under the zlib *
 *    license.                                                                *
 * 2. The zlib license header goes at the top of each source file, with       *
 *    appropriate copyright notice.                                           *
 * 3. This PasVulkan wrapper may be used only with the PasVulkan-own Vulkan   *
 *    Pascal header.                                                          *
 * 4. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/pasvulkan                                    *
 * 5. Write code which's compatible with Delphi >= 2009 and FreePascal >=     *
 *    3.1.1                                                                   *
 * 6. Don't use Delphi-only, FreePascal-only or Lazarus-only libraries/units, *
 *    but if needed, make it out-ifdef-able.                                  *
 * 7. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able.                                                      *
 * 8. Try to use const when possible.                                         *
 * 9. Make sure to comment out writeln, used while debugging.                 *
 * 10. Make sure the code compiles on 32-bit and 64-bit platforms (x86-32,    *
 *     x86-64, ARM, ARM64, etc.).                                             *
 * 11. Make sure the code runs on all platforms with Vulkan support           *
 *                                                                            *
 ******************************************************************************)
unit PasVulkan.HighResolutionTimer;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$m+}

interface

uses {$ifdef windows}
      Windows,
      MMSystem,
     {$else}
      {$ifdef unix}
       BaseUnix,
       Unix,
       UnixType,
       {$ifdef linux}
        linux,
       {$endif}
      {$else}
       SDL,
      {$endif}
     {$endif}
     SysUtils,
     Classes,
     SyncObjs,
     Math,
     PasVulkan.Types;

type PPpvHighResolutionTime=^PpvHighResolutionTime;
     PpvHighResolutionTime=^TpvHighResolutionTime;
     TpvHighResolutionTime=TpvInt64;

     TpvHighResolutionTimer=class
      private
       fFrequency:TpvInt64;
       fFrequencyShift:TpvInt32;
       fMillisecondInterval:TpvHighResolutionTime;
       fTwoMillisecondsInterval:TpvHighResolutionTime;
       fFourMillisecondsInterval:TpvHighResolutionTime;
       fQuarterSecondInterval:TpvHighResolutionTime;
       fMinuteInterval:TpvHighResolutionTime;
       fHourInterval:TpvHighResolutionTime;
      public
       constructor Create;
       destructor Destroy; override;
       function GetTime:TpvInt64;
       procedure Sleep(const aDelay:TpvHighResolutionTime);
       function ToFixedPointSeconds(const aTime:TpvHighResolutionTime):TpvInt64;
       function ToFloatSeconds(const aTime:TpvHighResolutionTime):TpvDouble;
       function FromFloatSeconds(const aTime:TpvDouble):TpvHighResolutionTime;
       function ToMilliseconds(const aTime:TpvHighResolutionTime):TpvInt64;
       function FromMilliseconds(const aTime:TpvInt64):TpvHighResolutionTime;
       function ToMicroseconds(const aTime:TpvHighResolutionTime):TpvInt64;
       function FromMicroseconds(const aTime:TpvInt64):TpvHighResolutionTime;
       function ToNanoseconds(const aTime:TpvHighResolutionTime):TpvInt64;
       function FromNanoseconds(const aTime:TpvInt64):TpvHighResolutionTime;
       property Frequency:TpvInt64 read fFrequency;
       property MillisecondInterval:TpvHighResolutionTime read fMillisecondInterval;
       property TwoMillisecondsInterval:TpvHighResolutionTime read fTwoMillisecondsInterval;
       property FourMillisecondsInterval:TpvHighResolutionTime read fFourMillisecondsInterval;
       property QuarterSecondInterval:TpvHighResolutionTime read fQuarterSecondInterval;
       property SecondInterval:TpvHighResolutionTime read fFrequency;
       property MinuteInterval:TpvHighResolutionTime read fMinuteInterval;
       property HourInterval:TpvHighResolutionTime read fHourInterval;
     end;

implementation

type TUInt128=packed record
{$ifdef BIG_ENDIAN}
      case byte of
       0:(
        Hi,Lo:TpvInt64;
       );
       1:(
        Q3,Q2,Q1,Q0:TpvUInt32;
       );
{$else}
      case byte of
       0:(
        Lo,Hi:TpvInt64;
       );
       1:(
        Q0,Q1,Q2,Q3:TpvUInt32;
       );
{$endif}
     end;

function AddWithCarry(const a,b:TpvUInt32;var Carry:TpvUInt32):TpvUInt32; {$ifdef caninline}inline;{$endif}
var r:TpvInt64;
begin
 r:=TpvInt64(a)+TpvInt64(b)+TpvInt64(Carry);
 Carry:=(r shr 32) and 1;
 result:=r and $ffffffff;
end;

function MultiplyWithCarry(const a,b:TpvUInt32;var Carry:TpvUInt32):TpvUInt32; {$ifdef caninline}inline;{$endif}
var r:TpvInt64;
begin
 r:=(TpvInt64(a)*TpvInt64(b))+TpvInt64(Carry);
 Carry:=r shr 32;
 result:=r and $ffffffff;
end;

function DivideWithRemainder(const a,b:TpvUInt32;var Remainder:TpvUInt32):TpvUInt32; {$ifdef caninline}inline;{$endif}
var r:TpvInt64;
begin
 r:=(TpvInt64(Remainder) shl 32) or a;
 Remainder:=r mod b;
 result:=r div b;
end;

procedure UInt64ToUInt128(var Dest:TUInt128;const x:TpvInt64); {$ifdef caninline}inline;{$endif}
begin
 Dest.Hi:=0;
 Dest.Lo:=x;
end;

procedure UInt128Add(var Dest:TUInt128;const x,y:TUInt128); {$ifdef caninline}inline;{$endif}
var a,b,c,d:TpvInt64;
begin
 a:=x.Hi shr 32;
 b:=x.Hi and $ffffffff;
 c:=x.Lo shr 32;
 d:=x.Lo and $ffffffff;
 inc(d,y.Lo and $ffffffff);
 inc(c,(y.Lo shr 32)+(d shr 32));
 inc(b,(y.Hi and $ffffffff)+(c shr 32));
 inc(a,(y.Hi shr 32)+(b shr 32));
 Dest.Hi:=((a and $ffffffff) shl 32) or (b and $ffffffff);
 Dest.Lo:=((c and $ffffffff) shl 32) or (d and $ffffffff);
end;

procedure UInt128Mul(var Dest:TUInt128;const x,y:TUInt128); {$ifdef caninline}inline;{$endif}
var c,xw,yw,dw:array[0..15] of TpvUInt32;
    i,j,k:TpvInt32;
    v:TpvUInt32;
begin
 for i:=0 to 15 do begin
  c[i]:=0;
 end;
 xw[7]:=(x.Lo shr 0) and $ffff;
 xw[6]:=(x.Lo shr 16) and $ffff;
 xw[5]:=(x.Lo shr 32) and $ffff;
 xw[4]:=(x.Lo shr 48) and $ffff;
 xw[3]:=(x.Hi shr 0) and $ffff;
 xw[2]:=(x.Hi shr 16) and $ffff;
 xw[1]:=(x.Hi shr 32) and $ffff;
 xw[0]:=(x.Hi shr 48) and $ffff;
 yw[7]:=(y.Lo shr 0) and $ffff;
 yw[6]:=(y.Lo shr 16) and $ffff;
 yw[5]:=(y.Lo shr 32) and $ffff;
 yw[4]:=(y.Lo shr 48) and $ffff;
 yw[3]:=(y.Hi shr 0) and $ffff;
 yw[2]:=(y.Hi shr 16) and $ffff;
 yw[1]:=(y.Hi shr 32) and $ffff;
 yw[0]:=(y.Hi shr 48) and $ffff;
 for i:=0 to 7 do begin
  for j:=0 to 7 do begin
   v:=xw[i]*yw[j];
   k:=i+j;
   inc(c[k],v shr 16);
   inc(c[k+1],v and $ffff);
  end;
 end;
 for i:=15 downto 1 do begin
  inc(c[i-1],c[i] shr 16);
  c[i]:=c[i] and $ffff;
 end;
 for i:=0 to 7 do begin
  dw[i]:=c[8+i];
 end;
 Dest.Hi:=(TpvInt64(dw[0] and $ffff) shl 48) or (TpvInt64(dw[1] and $ffff) shl 32) or (TpvInt64(dw[2] and $ffff) shl 16) or (TpvInt64(dw[3] and $ffff) shl 0);
 Dest.Lo:=(TpvInt64(dw[4] and $ffff) shl 48) or (TpvInt64(dw[5] and $ffff) shl 32) or (TpvInt64(dw[6] and $ffff) shl 16) or (TpvInt64(dw[7] and $ffff) shl 0);
end;

procedure UInt128Div64(var Dest:TUInt128;const Dividend:TUInt128;Divisor:TpvInt64); {$ifdef caninline}inline;{$endif}
var Quotient:TUInt128;
    Remainder:TpvInt64;
    Bit:TpvInt32;
begin
 Quotient:=Dividend;
 Remainder:=0;
 for Bit:=1 to 128 do begin
  Remainder:=(Remainder shl 1) or (ord((Quotient.Hi and $8000000000000000)<>0) and 1);
  Quotient.Hi:=(Quotient.Hi shl 1) or (Quotient.Lo shr 63);
  Quotient.Lo:=Quotient.Lo shl 1;
  if (TpvUInt32(Remainder shr 32)>TpvUInt32(Divisor shr 32)) or
     ((TpvUInt32(Remainder shr 32)=TpvUInt32(Divisor shr 32)) and (TpvUInt32(Remainder and $ffffffff)>=TpvUInt32(Divisor and $ffffffff))) then begin
   dec(Remainder,Divisor);
   Quotient.Lo:=Quotient.Lo or 1;
  end;
 end;
 Dest:=Quotient;
end;

procedure UInt128Mul64(var Dest:TUInt128;u,v:TpvInt64); {$ifdef caninline}inline;{$endif}
var u0,u1,v0,v1,k,t,w0,w1,w2:TpvInt64;
begin
 u1:=u shr 32;
 u0:=u and TpvInt64($ffffffff);
 v1:=v shr 32;
 v0:=v and TpvInt64($ffffffff);
 t:=u0*v0;
 w0:=t and TpvInt64($ffffffff);
 k:=t shr 32;
 t:=(u1*v0)+k;
 w1:=t and TpvInt64($ffffffff);
 w2:=t shr 32;
 t:=(u0*v1)+w1;
 k:=t shr 32;
 Dest.Lo:=(t shl 32)+w0;
 Dest.Hi:=((u1*v1)+w2)+k;
end;

constructor TpvHighResolutionTimer.Create;
begin
 inherited Create;
 fFrequencyShift:=0;
{$if defined(windows)}
 if QueryPerformanceFrequency(fFrequency) then begin
  while (fFrequency and $ffffffffe0000000)<>0 do begin
   fFrequency:=fFrequency shr 1;
   inc(fFrequencyShift);
  end;
 end else begin
  fFrequency:=1000;
 end;
{$elseif defined(linux) or defined(android)}
  fFrequency:=1000000000;
{$elseif defined(unix)}
  fFrequency:=1000000;
{$else}
  fFrequency:=1000;
{$ifend}
 fMillisecondInterval:=(fFrequency+500) div 1000;
 fTwoMillisecondsInterval:=(fFrequency+250) div 500;
 fFourMillisecondsInterval:=(fFrequency+125) div 250;
 fQuarterSecondInterval:=(fFrequency+2) div 4;
 fMinuteInterval:=fFrequency*60;
 fHourInterval:=fFrequency*3600;
end;

destructor TpvHighResolutionTimer.Destroy;
begin
 inherited Destroy;
end;

function TpvHighResolutionTimer.GetTime:TpvInt64;
{$if defined(linux) or defined(android)}
var NowTimeSpec:TimeSpec;
    ia,ib:TpvInt64;
{$elseif defined(unix)}
var tv:timeval;
    tz:timezone;
    ia,ib:TpvInt64;
{$ifend}
begin
{$if defined(windows)}
 if not QueryPerformanceCounter(result) then begin
  result:=timeGetTime;
 end;
{$elseif defined(linux) or defined(android)}
 clock_gettime(CLOCK_MONOTONIC,@NowTimeSpec);
 ia:=TpvInt64(NowTimeSpec.tv_sec)*TpvInt64(1000000000);
 ib:=NowTimeSpec.tv_nsec;
 result:=ia+ib;
{$elseif defined(unix)}
  tz.tz_minuteswest:=0;
  tz.tz_dsttime:=0;
  fpgettimeofday(@tv,@tz);
  ia:=TpvInt64(tv.tv_sec)*TpvInt64(1000000);
  ib:=tv.tv_usec;
  result:=ia+ib;
{$else}
 result:=SDL_GetTicks;
{$ifend}
 result:=result shr fFrequencyShift;
end;

procedure TpvHighResolutionTimer.Sleep(const aDelay:TpvInt64);
var EndTime,NowTime{$ifdef unix},SleepTime{$endif}:TpvInt64;
{$ifdef unix}
    req,rem:timespec;
{$endif}
begin
 if aDelay>0 then begin
{$if defined(windows)}
  NowTime:=GetTime;
  EndTime:=NowTime+aDelay;
  while (NowTime+fFourMillisecondsInterval)<EndTime do begin
   Sleep(1);
   NowTime:=GetTime;
  end;
  while (NowTime+fTwoMillisecondsInterval)<EndTime do begin
   Sleep(0);
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$elseif defined(linux) or defined(android)}
  NowTime:=GetTime;
  EndTime:=NowTime+aDelay;
  while (NowTime+fFourMillisecondsInterval)<EndTime do begin
   SleepTime:=((EndTime-NowTime)+2) shr 2;
   if SleepTime>0 then begin
    req.tv_sec:=SleepTime div 1000000000;
    req.tv_nsec:=SleepTime mod 10000000000;
    fpNanoSleep(@req,@rem);
    NowTime:=GetTime;
    continue;
   end;
   break;
  end;
  while (NowTime+fTwoMillisecondsInterval)<EndTime do begin
   ThreadSwitch;
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$elseif defined(unix)}
  NowTime:=GetTime;
  EndTime:=NowTime+aDelay;
  while (NowTime+fFourMillisecondsInterval)<EndTime do begin
   SleepTime:=((EndTime-NowTime)+2) shr 2;
   if SleepTime>0 then begin
    req.tv_sec:=SleepTime div 1000000;
    req.tv_nsec:=(SleepTime mod 1000000)*1000;
    fpNanoSleep(@req,@rem);
    NowTime:=GetTime;
    continue;
   end;
   break;
  end;
  while (NowTime+fTwoMillisecondsInterval)<EndTime do begin
   ThreadSwitch;
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$else}
  NowTime:=GetTime;
  EndTime:=NowTime+aDelay;
  while (NowTime+fFourMillisecondsInterval)<EndTime then begin
   SDL_Delay(1);
   NowTime:=GetTime;
  end;
  while (NowTime+fTwoMillisecondsInterval)<EndTime do begin
   SDL_Delay(0);
   NowTime:=GetTime;
  end;
  while NowTime<EndTime do begin
   NowTime:=GetTime;
  end;
{$ifend}
 end;
end;

function TpvHighResolutionTimer.ToFixedPointSeconds(const aTime:TpvHighResolutionTime):TpvInt64;
var a,b:TUInt128;
begin
 if fFrequency<>0 then begin
  if ((fFrequency or aTime) and TpvInt64($ffffffff00000000))=0 then begin
   result:=TpvInt64(TpvInt64(TpvInt64(aTime)*TpvInt64($100000000)) div TpvInt64(fFrequency));
  end else begin
   UInt128Mul64(a,aTime,TpvInt64($100000000));
   UInt128Div64(b,a,fFrequency);
   result:=b.Lo;
  end;
 end else begin
  result:=0;
 end;
end;

function TpvHighResolutionTimer.ToFloatSeconds(const aTime:TpvHighResolutionTime):TpvDouble;
begin
 if fFrequency<>0 then begin
  result:=aTime/fFrequency;
 end else begin
  result:=0;
 end;
end;

function TpvHighResolutionTimer.FromFloatSeconds(const aTime:TpvDouble):TpvHighResolutionTime;
begin
 if fFrequency<>0 then begin
  result:=trunc(aTime*fFrequency);
 end else begin
  result:=0;
 end;
end;

function TpvHighResolutionTimer.ToMilliseconds(const aTime:TpvHighResolutionTime):TpvInt64;
begin
 result:=aTime;
 if fFrequency<>1000 then begin
  result:=((aTime*1000)+((fFrequency+1) shr 1)) div fFrequency;
 end;
end;

function TpvHighResolutionTimer.FromMilliseconds(const aTime:TpvInt64):TpvHighResolutionTime;
begin
 result:=aTime;
 if fFrequency<>1000 then begin
  result:=((aTime*fFrequency)+500) div 1000;
 end;
end;

function TpvHighResolutionTimer.ToMicroseconds(const aTime:TpvHighResolutionTime):TpvInt64;
begin
 result:=aTime;
 if fFrequency<>1000000 then begin
  result:=((aTime*1000000)+((fFrequency+1) shr 1)) div fFrequency;
 end;
end;

function TpvHighResolutionTimer.FromMicroseconds(const aTime:TpvInt64):TpvHighResolutionTime;
begin
 result:=aTime;
 if fFrequency<>1000000 then begin
  result:=((aTime*fFrequency)+500000) div 1000000;
 end;
end;

function TpvHighResolutionTimer.ToNanoseconds(const aTime:TpvHighResolutionTime):TpvInt64;
begin
 result:=aTime;
 if fFrequency<>1000000000 then begin
  result:=((aTime*1000000000)+((fFrequency+1) shr 1)) div fFrequency;
 end;
end;

function TpvHighResolutionTimer.FromNanoseconds(const aTime:TpvInt64):TpvHighResolutionTime;
begin
 result:=aTime;
 if fFrequency<>1000000000 then begin
  result:=((aTime*fFrequency)+500000000) div 1000000000;
 end;
end;

initialization
{$ifdef windows}
 timeBeginPeriod(1);
{$endif}
finalization
{$ifdef windows}
 timeEndPeriod(1);
{$endif}
end.

