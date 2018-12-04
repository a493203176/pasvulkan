(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2018, Benjamin Rosseaux (benjamin@rosseaux.de)          *
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
unit PasVulkan.Techniques;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}

interface

uses SysUtils,
     Classes,
     Math,
     Vulkan,
     PasJSON,
     PasVulkan.Types,
     PasVulkan.Collections,
     PasVulkan.JSON;

type TpvTechniques=class
      public
       type TStringJSONItemObjectMap=TpvStringHashMap<TPasJSONItemObject>;
      private
       fPath:TpvUTF8String;
       fJSON:TPasJSONItemObject;
       fJSONTechniqueNameHashMap:TStringJSONItemObjectMap;
      public
       constructor Create(const aPath:TpvUTF8String='techniques');
       destructor Destroy; override;
     end;

implementation

uses PasVulkan.Application;

{ TpvTechniques }

constructor TpvTechniques.Create(const aPath:TpvUTF8String='techniques');
var FileNameList:TpvApplicationAssets.TFileNameList;
    FileName:TpvUTF8String;
    Stream:TStream;
    CurrentJSON:TPasJSONItem;
    BaseJSONItem,JSONItem:TPasJSONItem;
    BaseJSONItemObject:TPasJSONItemObject;
    JSONItemObjectProperty:TPasJSONItemObjectProperty;
begin

 inherited Create;

 fPath:=aPath;
 if (length(fPath)>0) and (fPath[length(fPath)] in ['/','\']) then begin
  Delete(fPath,length(fPath),1);
 end;

 fJSON:=TPasJSONItemObject.Create;

 fJSONTechniqueNameHashMap:=TStringJSONItemObjectMap.Create(nil);

 FileNameList:=pvApplication.Assets.GetDirectoryFileList(fPath);
 for FileName in FileNameList do begin
  if ExtractFileExt(String(FileName))='.techniques' then begin
   Stream:=pvApplication.Assets.GetAssetStream(fPath+'/'+FileName);
   if assigned(Stream) then begin
    try
     CurrentJSON:=TPasJSON.Parse(Stream,TPasJSON.SimplifiedJSONModeFlags+[TPasJSONModeFlag.HexadecimalNumbers]);
     if assigned(CurrentJSON) then begin
      try
       if CurrentJSON is TPasJSONItemObject then begin
        fJSON.Merge(CurrentJSON);
       end;
      finally
       FreeAndNil(CurrentJSON);
      end;
     end;
    finally
     FreeAndNil(Stream);
    end;
   end;
  end;
 end;

 TpvJSONUtils.ResolveTemplates(fJSON);

 BaseJSONItem:=fJSON.Properties['techniques'];

 if assigned(BaseJSONItem) then begin

  TpvJSONUtils.ResolveInheritances(BaseJSONItem);

  if BaseJSONItem is TPasJSONItemObject then begin

   BaseJSONItemObject:=TPasJSONItemObject(BaseJSONItem);

   for JSONItemObjectProperty in BaseJSONItemObject do begin
    JSONItem:=JSONItemObjectProperty.Value;
    if assigned(JSONItem) and (JSONItem is TPasJSONItemObject) then begin
     fJSONTechniqueNameHashMap.Add(JSONItemObjectProperty.Key,TPasJSONItemObject(JSONItem));
    end;
   end;

  end;

 end;

end;

destructor TpvTechniques.Destroy;
begin
 FreeAndNil(fJSONTechniqueNameHashMap);
 FreeAndNil(fJSON);
 inherited Destroy;
end;

end.
