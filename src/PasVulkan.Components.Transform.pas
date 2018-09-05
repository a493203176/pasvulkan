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
unit PasVulkan.Components.Transform;
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

uses SysUtils,
     Classes,
     Math,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.EntityComponentSystem;

type PpvComponentTransform=^TpvComponentTransform;
     TpvComponentTransform=record
      public
       type TFlag=
             (
              Static=0,
              RelativePosition=1,
              RelativeRotation=2,
              RelativeScale=3
             );
            TFlags=set of TFlag;
      public
       Parent:TpvEntityID;
       Flags:TFlags;
       Position:TpvVector3;
       Rotation:TpvQuaternion;
       Scale:TpvVector3;
     end;

const pvComponentTransformDefault:TpvComponentTransform=
       (
        Parent:$ffffffff;
        Flags:[];
        Position:(x:0.0;y:0.0;z:0.0);
        Rotation:(x:0.0;y:0.0;z:0.0;w:1.0);
        Scale:(x:1.0;y:1.0;z:1.0);
       );

var pvComponentTransform:TpvRegisteredComponentType=nil;

    pvComponentTransformID:TpvComponentTypeID=0;

implementation

procedure Register;
const Flags:array[TpvComponentTransform.TFlag] of TpvComponentTransform.TFlags=
       (
        [TpvComponentTransform.TFlag.Static],
        [TpvComponentTransform.TFlag.RelativePosition],
        [TpvComponentTransform.TFlag.RelativeRotation],
        [TpvComponentTransform.TFlag.RelativeScale]
       );
begin

 pvComponentTransform:=TpvRegisteredComponentType.Create('transform',
                                                         'Transform',
                                                         ['Base','Transform'],
                                                         SizeOf(TpvComponentTransform),
                                                         @pvComponentTransformDefault);

 pvComponentTransformID:=pvComponentTransform.ID;

 pvComponentTransform.Add('parent',
                          'Parent',
                          TpvRegisteredComponentType.TField.TElementType.EntityID,
                          SizeOf(PpvComponentTransform(nil)^.Parent),
                          1,
                          TpvPtrUInt(@PpvComponentTransform(nil)^.Parent),
                          SizeOf(PpvComponentTransform(nil)^.Parent),
                          []
                         );

 pvComponentTransform.Add('flags',
                          'Flags',
                          TpvRegisteredComponentType.TField.TElementType.Flags,
                          SizeOf(PpvComponentTransform(nil)^.Flags),
                          1,
                          TpvPtrUInt(@PpvComponentTransform(nil)^.Flags),
                          SizeOf(PpvComponentTransform(nil)^.Flags),
                          [TpvRegisteredComponentType.TField.TEnumerationOrFlag.Create(TpvRegisteredComponentType.GetSetOrdValue(TypeInfo(TpvComponentTransform.TFlags),Flags[TpvComponentTransform.TFlag.Static]),
                                                                                       'static',
                                                                                       'Static'),
                           TpvRegisteredComponentType.TField.TEnumerationOrFlag.Create(TpvRegisteredComponentType.GetSetOrdValue(TypeInfo(TpvComponentTransform.TFlags),Flags[TpvComponentTransform.TFlag.RelativePosition]),
                                                                                       'relativeposition',
                                                                                       'Relative position'),
                           TpvRegisteredComponentType.TField.TEnumerationOrFlag.Create(TpvRegisteredComponentType.GetSetOrdValue(TypeInfo(TpvComponentTransform.TFlags),Flags[TpvComponentTransform.TFlag.RelativeRotation]),
                                                                                       'relativerotation',
                                                                                       'Relative rotation'),
                           TpvRegisteredComponentType.TField.TEnumerationOrFlag.Create(TpvRegisteredComponentType.GetSetOrdValue(TypeInfo(TpvComponentTransform.TFlags),Flags[TpvComponentTransform.TFlag.RelativeScale]),
                                                                                       'relativescale',
                                                                                       'Relative scale')
                          ]
                         );

 pvComponentTransform.Add('position',
                          'Position',
                          TpvRegisteredComponentType.TField.TElementType.FloatingPoint,
                          SizeOf(PpvComponentTransform(nil)^.Position.x),
                          3,
                          TpvPtrUInt(@PpvComponentTransform(nil)^.Position),
                          SizeOf(PpvComponentTransform(nil)^.Position),
                          []
                         );

 pvComponentTransform.Add('rotation',
                          'Rotation',
                          TpvRegisteredComponentType.TField.TElementType.FloatingPoint,
                          SizeOf(PpvComponentTransform(nil)^.Rotation.x),
                          4,
                          TpvPtrUInt(@PpvComponentTransform(nil)^.Rotation),
                          SizeOf(PpvComponentTransform(nil)^.Rotation),
                          []
                         );

 pvComponentTransform.Add('scale',
                          'Scale',
                          TpvRegisteredComponentType.TField.TElementType.FloatingPoint,
                          SizeOf(PpvComponentTransform(nil)^.Scale.x),
                          3,
                          TpvPtrUInt(@PpvComponentTransform(nil)^.Scale),
                          SizeOf(PpvComponentTransform(nil)^.Scale),
                          []
                         );

end;

initialization
 Register;
end.


