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
     PasVulkan.Framework,
     PasVulkan.JSON;

type TpvTechniques=class
      public
        type TShader=class;
             TShaderList=TpvObjectGenericList<TShader>;
             TShaderNameMap=TpvStringHashMap<TShader>;
             TShader=class
              private
               fTechniques:TpvTechniques;
               fName:TpvUTF8String;
               fLoaded:boolean;
               fShaderModule:TpvVulkanShaderModule;
               fReflectionData:TpvVulkanShaderModuleReflectionData;
              public
               constructor Create(const aTechniques:TpvTechniques); reintroduce;
               destructor Destroy; override;
               procedure Load;
              public
               property ReflectionData:TpvVulkanShaderModuleReflectionData read fReflectionData;
              published
               property Name:TpvUTF8String read fName;
               property Loaded:boolean read fLoaded;
               property ShaderModule:TpvVulkanShaderModule read fShaderModule;
             end;
            TTechnique=class;
            TTechniqueList=TpvObjectGenericList<TTechnique>;
            TTechniqueNameMap=TpvStringHashMap<TTechnique>;
            TTechnique=class
             public
              type TPass=class;
                   TPassList=TpvObjectGenericList<TPass>;
                   TPass=class
                    public
                     type TSpecializationConstant=record
                           public
                            type TDataType=
                                  (
                                   Boolean,
                                   Number
                                  );
                           public
                            Name:TpvUTF8String;
                            case DataType:TDataType of
                             TDataType.Boolean:(
                              BooleanValue:boolean;
                             );
                             TDataType.Number:(
                              NumberValue:TpvDouble;
                             );
                          end;
                          PSpecializationConstant=^TSpecializationConstant;
                          TSpecializationConstants=array of TSpecializationConstant;
                          TRenderState=record
                           public

                            TessellationState:TVkPipelineTessellationStateCreateInfo;

                            RasterizationState:TVkPipelineRasterizationStateCreateInfo;

                            DepthStencilState:TVkPipelineDepthStencilStateCreateInfo;

                            ColorBlendState:TVkPipelineColorBlendStateCreateInfo;

                            ColorBlendAttachmentStates:TVkPipelineColorBlendAttachmentStateArray;

                          end;
                          PRenderState=^TRenderState;
                     const DefaultRenderState:TRenderState=
                            (

                             TessellationState:(
                              sType:VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO;
                              pNext:nil;
                              flags:0;
                              patchControlPoints:0;
                             );

                             RasterizationState:(
                              sType:VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
                              pNext:nil;
                              depthClampEnable:VK_TRUE;
                              rasterizerDiscardEnable:VK_FALSE;
                              polygonMode:VK_POLYGON_MODE_FILL;
                              cullMode:TVkCullModeFlags(VK_CULL_MODE_NONE);
                              frontFace:VK_FRONT_FACE_COUNTER_CLOCKWISE;
                              depthBiasEnable:VK_TRUE;
                              depthBiasConstantFactor:0.0;
                              depthBiasClamp:0.0;
                              depthBiasSlopeFactor:0.0;
                              lineWidth:1.0;
                             );

                             DepthStencilState:(
                              sType:VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
                              pNext:nil;
                              flags:0;
                              depthTestEnable:VK_TRUE;
                              depthWriteEnable:VK_TRUE;
                              depthCompareOp:VK_COMPARE_OP_LESS_OR_EQUAL;
                              depthBoundsTestEnable:VK_FALSE;
                              stencilTestEnable:VK_FALSE;
                              front:(
                               failOp:VK_STENCIL_OP_KEEP;
                               depthFailOp:VK_STENCIL_OP_KEEP;
                               compareOp:VK_COMPARE_OP_ALWAYS;
                               compareMask:0;
                               writeMask:0;
                               reference:0;
                              );
                              back:(
                               failOp:VK_STENCIL_OP_KEEP;
                               depthFailOp:VK_STENCIL_OP_KEEP;
                               compareOp:VK_COMPARE_OP_ALWAYS;
                               compareMask:0;
                               writeMask:0;
                               reference:0;
                              );
                              minDepthBounds:0.0;
                              maxDepthBounds:1.0;
                             );

                             ColorBlendState:(
                              sType:VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
                              pNext:nil;
                              flags:0;
                              logicOpEnable:VK_FALSE;
                              logicOp:VK_LOGIC_OP_NO_OP;
                              attachmentCount:0;
                              pAttachments:nil;
                              blendConstants:(
                               0.0,
                               0.0,
                               0.0,
                               0.0
                              );
                             );

                             ColorBlendAttachmentStates:nil;

                            );
                    private
                     fTechnique:TTechnique;
                     fIndex:TpvSizeInt;
                     fName:TpvUTF8String;
                     fVertexShader:TShader;
                     fTessellationControlShader:TShader;
                     fTessellationEvalutionShader:TShader;
                     fGeometryShader:TShader;
                     fFragmentShader:TShader;
                     fSpecializationConstants:TSpecializationConstants;
                     fRenderState:TRenderState;
                     fVulkanDescriptorSetLayouts:array of TpvVulkanDescriptorSetLayout;
                     fVulkanPipelineLayout:TpvVulkanPipelineLayout;
                     procedure LoadFromJSONObject(const aRootJSONObject:TPasJSONItemObject);
                     procedure Load;
                    public
                     constructor Create(const aTechnique:TTechnique); reintroduce;
                     destructor Destroy; override;
                     procedure InitializePipeline(const aPipeline:TpvVulkanPipeline;
                                                  const aRenderPass:TpvVulkanRenderPass;
                                                  const aPrimitiveTopology:TVkPrimitiveTopology;
                                                  const aPrimitiveRestartEnable:boolean);
                     property VertexShader:TShader read fVertexShader;
                     property TessellationControlShader:TShader read fTessellationControlShader;
                     property TessellationEvalutionShader:TShader read fTessellationEvalutionShader;
                     property GeometryShader:TShader read fGeometryShader;
                     property FragmentShader:TShader read fFragmentShader;
                     property SpecializationConstants:TSpecializationConstants read fSpecializationConstants;
                   end;
             private
              fTechniques:TpvTechniques;
              fName:TpvUTF8String;
              fVariantTechniqueNameMap:TTechniqueNameMap;
              fPasses:TPassList;
              procedure LoadFromJSONObject(const aRootJSONObject:TPasJSONItemObject);
             public
              constructor Create(const aParent:TpvTechniques); reintroduce;
              destructor Destroy; override;
             published
              property VariantTechniqueByName:TTechniqueNameMap read fVariantTechniqueNameMap;
              property Passes:TPassList read fPasses;
            end;
      private
       fPath:TpvUTF8String;
       fShaders:TShaderList;
       fShaderNameMap:TShaderNameMap;
       fTechniques:TTechniqueList;
       fTechniqueNameMap:TTechniqueNameMap;
      public
       constructor Create(const aPath:TpvUTF8String='techniques');
       destructor Destroy; override;
      published
       property TechniqueByName:TTechniqueNameMap read fTechniqueNameMap;
     end;

implementation

uses PasVulkan.Application;

{ TpvTechniques.TShader }

constructor TpvTechniques.TShader.Create(const aTechniques:TpvTechniques);
begin

 inherited Create;

 fTechniques:=aTechniques;

 fLoaded:=false;

 fShaderModule:=nil;

end;

destructor TpvTechniques.TShader.Destroy;
begin

 FreeAndNil(fShaderModule);

 Finalize(fReflectionData);

 inherited Destroy;

end;

procedure TpvTechniques.TShader.Load;
begin
 if not fLoaded then begin
  fShaderModule:=TpvVulkanShaderModule.Create(pvApplication.VulkanDevice,pvApplication.Assets.GetAssetStream('shaders/'+fName));
  fReflectionData:=fShaderModule.GetReflectionData;
  fLoaded:=true;
 end;
end;

{ TpvTechniques.TTechnique.TPass }

constructor TpvTechniques.TTechnique.TPass.Create(const aTechnique:TTechnique);
begin

 inherited Create;

 fTechnique:=aTechnique;

 fIndex:=-1;

 fName:='';

 fSpecializationConstants:=nil;

 fRenderState:=DefaultRenderState;

 fVulkanDescriptorSetLayouts:=nil;

 fVulkanPipelineLayout:=nil;

end;

destructor TpvTechniques.TTechnique.TPass.Destroy;
var Index:TpvSizeInt;
begin

 fSpecializationConstants:=nil;

 for Index:=0 to length(fVulkanDescriptorSetLayouts)-1 do begin
  FreeAndNil(fVulkanDescriptorSetLayouts[Index]);
 end;

 fVulkanDescriptorSetLayouts:=nil;

 inherited Destroy;

end;

procedure TpvTechniques.TTechnique.TPass.LoadFromJSONObject(const aRootJSONObject:TPasJSONItemObject);
 function GetShader(const aName:TpvUTF8String):TShader;
 begin
  if length(aName)>0 then begin
   result:=fTechnique.fTechniques.fShaderNameMap[aName];
   if not assigned(result) then begin
    result:=TShader.Create(fTechnique.fTechniques);
    try
     result.fName:=aName;
    finally
     fTechnique.fTechniques.fShaders.Add(result);
    end;
    fTechnique.fTechniques.fShaderNameMap[aName]:=result;
   end;
  end else begin
   result:=nil;
  end;
 end;
var Index,Count:TpvSizeInt;
    SectionJSONItem,JSONItem:TPasJSONItem;
    SectionJSONItemObject:TPasJSONItemObject;
    JSONItemObjectProperty:TPasJSONItemObjectProperty;
    SpecializationConstant:TSpecializationConstant;
begin

 begin
  SectionJSONItem:=aRootJSONObject.Properties['shaders'];
  if assigned(SectionJSONItem) and (SectionJSONItem is TPasJSONItemObject) then begin
   SectionJSONItemObject:=TPasJSONItemObject(SectionJSONItem);
   fVertexShader:=GetShader(TPasJSON.GetString(SectionJSONItemObject.Properties['vertex'],''));
   fTessellationControlShader:=GetShader(TPasJSON.GetString(SectionJSONItemObject.Properties['tessellationControl'],''));
   fTessellationEvalutionShader:=GetShader(TPasJSON.GetString(SectionJSONItemObject.Properties['tessellationEvalution'],''));
   fGeometryShader:=GetShader(TPasJSON.GetString(SectionJSONItemObject.Properties['geometry'],''));
   fFragmentShader:=GetShader(TPasJSON.GetString(SectionJSONItemObject.Properties['fragment'],''));
  end;
 end;

 begin
  SectionJSONItem:=aRootJSONObject.Properties['specializationConstants'];
  if assigned(SectionJSONItem) and (SectionJSONItem is TPasJSONItemObject) then begin
   SectionJSONItemObject:=TPasJSONItemObject(SectionJSONItem);
   Count:=0;
   try
    for JSONItemObjectProperty in SectionJSONItemObject do begin
     if (length(JSONItemObjectProperty.Key)>0) and
        assigned(JSONItemObjectProperty.Value) then begin
      SpecializationConstant.Name:=JSONItemObjectProperty.Key;
      if JSONItemObjectProperty.Value is TPasJSONItemBoolean then begin
       SpecializationConstant.DataType:=TSpecializationConstant.TDataType.Boolean;
       SpecializationConstant.BooleanValue:=TPasJSONItemBoolean(JSONItemObjectProperty.Value).Value;
      end else begin
       SpecializationConstant.DataType:=TSpecializationConstant.TDataType.Number;
       SpecializationConstant.NumberValue:=TPasJSON.GetNumber(JSONItemObjectProperty.Value,0.0);
      end;
      Index:=Count;
      inc(Count);
      if length(fSpecializationConstants)<Count then begin
       SetLength(fSpecializationConstants,Count*2);
      end;
      fSpecializationConstants[Index]:=SpecializationConstant;
     end;
    end;
   finally
    SetLength(fSpecializationConstants,Count);
   end;
  end;
 end;

end;

procedure TpvTechniques.TTechnique.TPass.Load;
type TShaderVariable=record
      StorageClass:TpvVulkanShaderModuleReflectionStorageClass;
      Location:TpvUInt32;
      Binding:TpvUInt32;
      DescriptorSet:TpvUInt32;
      Size:TVkSize;
      StageFlags:TVkShaderStageFlags;
      ImageDim:TpvVulkanShaderModuleReflectionDim;
      Count:TpvUInt32;
      TypeKind:TpvVulkanShaderModuleReflectionTypeKind;
     end;
     PShaderVariable=^TShaderVariable;
     TShaderVariables=TpvDynamicArray<TShaderVariable>;
var ShaderVariables:TShaderVariables;
    PushConstantRange:TVkPushConstantRange;
    CountDescriptorSets:TpvSizeInt;
 procedure ScanShader(const aShader:TShader;const aStageFlags:TVkShaderStageFlags);
 var Index,OtherIndex,Type_:TpvSizeInt;
     Variable:PpvVulkanShaderModuleReflectionVariable;
     ShaderVariable,
     TemporaryShaderVariable:PShaderVariable;
 begin
  for Index:=0 to length(aShader.fReflectionData.Variables)-1 do begin
   Variable:=@aShader.fReflectionData.Variables[Index];
   case Variable^.StorageClass of
    TpvVulkanShaderModuleReflectionStorageClass.Uniform,
    TpvVulkanShaderModuleReflectionStorageClass.StorageBuffer:begin
     ShaderVariable:=nil;
     for OtherIndex:=0 to ShaderVariables.Count-1 do begin
      TemporaryShaderVariable:=@ShaderVariables.Items[OtherIndex];
      if (TemporaryShaderVariable^.StorageClass=Variable^.StorageClass) and
         (TemporaryShaderVariable^.Location=Variable^.Location) and
         (TemporaryShaderVariable^.Binding=Variable^.Binding) and
         (TemporaryShaderVariable^.DescriptorSet=Variable^.DescriptorSet) then begin
       ShaderVariable:=TemporaryShaderVariable;
       break;
      end;
     end;
     if not assigned(ShaderVariable) then begin
      OtherIndex:=ShaderVariables.AddNew;
      ShaderVariable:=@ShaderVariables.Items[OtherIndex];
      ShaderVariable^.StorageClass:=Variable^.StorageClass;
      ShaderVariable^.Location:=Variable^.Location;
      ShaderVariable^.Binding:=Variable^.Binding;
      ShaderVariable^.DescriptorSet:=Variable^.DescriptorSet;
      ShaderVariable^.StageFlags:=0;
      ShaderVariable^.Size:=0;
      ShaderVariable^.Count:=1;
      ShaderVariable^.TypeKind:=TpvVulkanShaderModuleReflectionTypeKind.TypeStruct;
      Type_:=Variable.Type_;
      while Type_>=0 do begin
       case aShader.fReflectionData.Types[Type_].TypeKind of
        TpvVulkanShaderModuleReflectionTypeKind.TypePointer:begin
         Type_:=aShader.fReflectionData.Types[Type_].PointerTypeIndex;
         break;
        end;
        TpvVulkanShaderModuleReflectionTypeKind.TypeArray:begin
         ShaderVariable^.Count:=ShaderVariable^.Count*aShader.fReflectionData.Types[Type_].ArraySize;
         Type_:=aShader.fReflectionData.Types[Type_].ArrayTypeIndex;
         break;
        end;
        TpvVulkanShaderModuleReflectionTypeKind.TypeSampler,
        TpvVulkanShaderModuleReflectionTypeKind.TypeSampledImage:begin
         ShaderVariable^.TypeKind:=aShader.fReflectionData.Types[Type_].TypeKind;
         break;
        end;
        TpvVulkanShaderModuleReflectionTypeKind.TypeStruct:begin
         ShaderVariable^.TypeKind:=TpvVulkanShaderModuleReflectionTypeKind.TypeStruct;
         break;
        end;
        else begin
         break;
        end;
       end;
      end;
     end;
     ShaderVariable^.StageFlags:=ShaderVariable^.StageFlags or aStageFlags;
     if ShaderVariable^.Size<(Variable^.Offset+Variable^.Size) then begin
      ShaderVariable^.Size:=Variable^.Offset+Variable^.Size;
     end;
     if CountDescriptorSets<=Variable^.DescriptorSet then begin
      CountDescriptorSets:=Variable^.DescriptorSet+1;
     end;
   end;
    TpvVulkanShaderModuleReflectionStorageClass.PushConstant:begin
     PushConstantRange.stageFlags:=PushConstantRange.stageFlags or aStageFlags;
     PushConstantRange.offset:=0;
     if PushConstantRange.size<(Variable^.Offset+Variable^.Size) then begin
      PushConstantRange.size:=Variable^.Offset+Variable^.Size;
     end;
    end;
    TpvVulkanShaderModuleReflectionStorageClass.Image:begin
     ShaderVariable:=nil;
     for OtherIndex:=0 to ShaderVariables.Count-1 do begin
      TemporaryShaderVariable:=@ShaderVariables.Items[OtherIndex];
      if (TemporaryShaderVariable^.StorageClass=Variable^.StorageClass) and
         (TemporaryShaderVariable^.Location=Variable^.Location) and
         (TemporaryShaderVariable^.Binding=Variable^.Binding) and
         (TemporaryShaderVariable^.DescriptorSet=Variable^.DescriptorSet) then begin
       ShaderVariable:=TemporaryShaderVariable;
       break;
      end;
     end;
     if not assigned(ShaderVariable) then begin
      OtherIndex:=ShaderVariables.AddNew;
      ShaderVariable:=@ShaderVariables.Items[OtherIndex];
      ShaderVariable^.StorageClass:=Variable^.StorageClass;
      ShaderVariable^.Location:=Variable^.Location;
      ShaderVariable^.Binding:=Variable^.Binding;
      ShaderVariable^.DescriptorSet:=Variable^.DescriptorSet;
      ShaderVariable^.StageFlags:=0;
      ShaderVariable^.Size:=0;
      ShaderVariable^.ImageDim:=TpvVulkanShaderModuleReflectionDim._1D;
      ShaderVariable^.Count:=1;
      Type_:=Variable.Type_;
      while Type_>=0 do begin
       case aShader.fReflectionData.Types[Type_].TypeKind of
        TpvVulkanShaderModuleReflectionTypeKind.TypePointer:begin
         Type_:=aShader.fReflectionData.Types[Type_].PointerTypeIndex;
         break;
        end;
        TpvVulkanShaderModuleReflectionTypeKind.TypeArray:begin
         ShaderVariable^.Count:=ShaderVariable^.Count*aShader.fReflectionData.Types[Type_].ArraySize;
         Type_:=aShader.fReflectionData.Types[Type_].ArrayTypeIndex;
         break;
        end;
        TpvVulkanShaderModuleReflectionTypeKind.TypeImage:begin
         ShaderVariable^.ImageDim:=aShader.fReflectionData.Types[Type_].ImageDim;
         break;
        end;
        else begin
         break;
        end;
       end;
      end;
     end;
     ShaderVariable^.StageFlags:=ShaderVariable^.StageFlags or aStageFlags;
    end;
   end;
  end;
 end;
var Index,Type_:TpvSizeInt;
    ShaderVariable:PShaderVariable;
    DescriptorSetLayout:TpvVulkanDescriptorSetLayout;
    DescriptorType:TVkDescriptorType;
begin
 if not assigned(fVulkanPipelineLayout) then begin
  fVulkanPipelineLayout:=TpvVulkanPipelineLayout.Create(pvApplication.VulkanDevice);
  try
   ShaderVariables.Initialize;
   try
    PushConstantRange.stageFlags:=0;
    CountDescriptorSets:=0;
    if assigned(fVertexShader) then begin
     fVertexShader.Load;
     ScanShader(fVertexShader,TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_VERTEX_BIT));
    end;
    if assigned(fTessellationControlShader) then begin
     fTessellationControlShader.Load;
     ScanShader(fTessellationControlShader,TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT));
    end;
    if assigned(fTessellationEvalutionShader) then begin
     fTessellationEvalutionShader.Load;
     ScanShader(fTessellationEvalutionShader,TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT));
    end;
    if assigned(fGeometryShader) then begin
     fGeometryShader.Load;
     ScanShader(fGeometryShader,TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_GEOMETRY_BIT));
    end;
    if assigned(fFragmentShader) then begin
     fFragmentShader.Load;
     ScanShader(fFragmentShader,TVkShaderStageFlags(TVkShaderStageFlagBits.VK_SHADER_STAGE_FRAGMENT_BIT));
    end;
    SetLength(fVulkanDescriptorSetLayouts,CountDescriptorSets);
    for Index:=0 to CountDescriptorSets-1 do begin
     fVulkanDescriptorSetLayouts[Index]:=TpvVulkanDescriptorSetLayout.Create(pvApplication.VulkanDevice);
    end;
    for Index:=0 to ShaderVariables.Count-1 do begin
     ShaderVariable:=@ShaderVariables.Items[Index];
     case ShaderVariable^.StorageClass of
      TpvVulkanShaderModuleReflectionStorageClass.Uniform,
      TpvVulkanShaderModuleReflectionStorageClass.StorageBuffer,
      TpvVulkanShaderModuleReflectionStorageClass.Image:begin
       DescriptorSetLayout:=fVulkanDescriptorSetLayouts[ShaderVariable^.DescriptorSet];
       case ShaderVariable^.StorageClass of
        TpvVulkanShaderModuleReflectionStorageClass.Uniform:begin
         case ShaderVariable^.TypeKind of
          TpvVulkanShaderModuleReflectionTypeKind.TypeSampler:begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_SAMPLER;
          end;
          TpvVulkanShaderModuleReflectionTypeKind.TypeSampledImage:begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
          end;
          else begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
          end;
         end;
        end;
        TpvVulkanShaderModuleReflectionStorageClass.Image:begin
         case ShaderVariable^.ImageDim of
          TpvVulkanShaderModuleReflectionDim._1D,
          TpvVulkanShaderModuleReflectionDim._2D,
          TpvVulkanShaderModuleReflectionDim._3D,
          TpvVulkanShaderModuleReflectionDim.Cube,
          TpvVulkanShaderModuleReflectionDim.Rect:begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE;
          end;
          TpvVulkanShaderModuleReflectionDim.Buffer:begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER;
          end;
          TpvVulkanShaderModuleReflectionDim.SubpassData:begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT;
          end;
          else begin
           DescriptorType:=VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
           Assert(false);
          end;
         end;
        end;
        else {TpvVulkanShaderModuleReflectionStorageClass.StorageBuffer:}begin
         DescriptorType:=VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        end;
       end;
       DescriptorSetLayout.AddBinding(ShaderVariable^.Binding,
                                      DescriptorType,
                                      ShaderVariable^.Count,
                                      ShaderVariable^.StageFlags,
                                      []
                                     );
      end;
      else begin
      end;
     end;
    end;
    if PushConstantRange.stageFlags<>0 then begin
     fVulkanPipelineLayout.AddPushConstantRange(PushConstantRange);
    end;
   finally
    ShaderVariables.Finalize;
   end;
  finally
   fVulkanPipelineLayout.Initialize;
  end;
 end;
end;

procedure TpvTechniques.TTechnique.TPass.InitializePipeline(const aPipeline:TpvVulkanPipeline;
                                                            const aRenderPass:TpvVulkanRenderPass;
                                                            const aPrimitiveTopology:TVkPrimitiveTopology;
                                                            const aPrimitiveRestartEnable:boolean);
begin
 Load;
 TpvVulkanGraphicsPipeline(aPipeline).InputAssemblyState.Topology:=aPrimitiveTopology;
 TpvVulkanGraphicsPipeline(aPipeline).InputAssemblyState.PrimitiveRestartEnable:=aPrimitiveRestartEnable;
 TpvVulkanGraphicsPipeline(aPipeline).TessellationState.TessellationStateCreateInfo^:=fRenderState.TessellationState;
 TpvVulkanGraphicsPipeline(aPipeline).RasterizationState.RasterizationStateCreateInfo^:=fRenderState.RasterizationState;
 TpvVulkanGraphicsPipeline(aPipeline).DepthStencilState.DepthStencilStateCreateInfo^:=fRenderState.DepthStencilState;
 TpvVulkanGraphicsPipeline(aPipeline).ColorBlendState.ColorBlendStateCreateInfo^:=fRenderState.ColorBlendState;
 if length(fRenderState.ColorBlendAttachmentStates)>0 then begin
  TpvVulkanGraphicsPipeline(aPipeline).ColorBlendState.AddColorBlendAttachmentStates(fRenderState.ColorBlendAttachmentStates);
 end;
end;

{ TpvTechniques.TTechnique }

constructor TpvTechniques.TTechnique.Create(const aParent:TpvTechniques);
begin

 inherited Create;

 fTechniques:=aParent;

 fVariantTechniqueNameMap:=TTechniqueNameMap.Create(nil);

 fPasses:=TPassList.Create;

end;

destructor TpvTechniques.TTechnique.Destroy;
begin

 FreeAndNil(fPasses);

 FreeAndNil(fVariantTechniqueNameMap);

 inherited Destroy;
end;

procedure TpvTechniques.TTechnique.LoadFromJSONObject(const aRootJSONObject:TPasJSONItemObject);
var SectionJSONItem,JSONItem:TPasJSONItem;
    SectionJSONItemObject:TPasJSONItemObject;
    JSONItemObjectProperty:TPasJSONItemObjectProperty;
    VariantTechniqueName:TpvUTF8String;
    VariantTechnique:TTechnique;
    Pass:TPass;
begin

 begin
  SectionJSONItem:=aRootJSONObject.Properties['variants'];
  if assigned(SectionJSONItem) and (SectionJSONItem is TPasJSONItemObject) then begin
   SectionJSONItemObject:=TPasJSONItemObject(SectionJSONItem);
   for JSONItemObjectProperty in SectionJSONItemObject do begin
    if length(JSONItemObjectProperty.Key)>0 then begin
     VariantTechniqueName:=TPasJSON.GetString(JSONItemObjectProperty.Value,'');
     if length(VariantTechniqueName)>0 then begin
      VariantTechnique:=fTechniques.fTechniqueNameMap[VariantTechniqueName];
      if assigned(VariantTechnique) then begin
       fVariantTechniqueNameMap.Add(JSONItemObjectProperty.Key,VariantTechnique);
      end;
     end;
    end;
   end;
  end;
 end;

 begin
  SectionJSONItem:=aRootJSONObject.Properties['passes'];
  if assigned(SectionJSONItem) and (SectionJSONItem is TPasJSONItemObject) then begin
   SectionJSONItemObject:=TPasJSONItemObject(SectionJSONItem);
   for JSONItemObjectProperty in SectionJSONItemObject do begin
    if length(JSONItemObjectProperty.Key)>0 then begin
     if assigned(JSONItemObjectProperty.Value) and
        (JSONItemObjectProperty.Value is TPasJSONItemObject) then begin
      Pass:=TPass.Create(self);
      try
       Pass.fName:=JSONItemObjectProperty.Key;
      finally
       Pass.fIndex:=fPasses.Add(Pass);
      end;
      Pass.LoadFromJSONObject(TPasJSONItemObject(JSONItemObjectProperty.Value));
     end;
    end;
   end;
  end;
 end;

end;

{ TpvTechniques }

constructor TpvTechniques.Create(const aPath:TpvUTF8String='techniques');
var FileNameList:TpvApplicationAssets.TFileNameList;
    FileName:TpvUTF8String;
    Stream:TStream;
    JSONTechniques:TPasJSONItemObject;
    CurrentJSON:TPasJSONItem;
    BaseJSONItem,JSONItem:TPasJSONItem;
    BaseJSONItemObject:TPasJSONItemObject;
    JSONItemObjectProperty:TPasJSONItemObjectProperty;
    Technique:TTechnique;
begin

 inherited Create;

 fShaders:=TShaderList.Create;
 fShaders.OwnsObjects:=true;

 fShaderNameMap:=TShaderNameMap.Create(nil);

 fTechniques:=TTechniqueList.Create;
 fTechniques.OwnsObjects:=true;

 fTechniqueNameMap:=TTechniqueNameMap.Create(nil);

 fPath:=aPath;
 if (length(fPath)>0) and (fPath[length(fPath)] in ['/','\']) then begin
  Delete(fPath,length(fPath),1);
 end;

 JSONTechniques:=TPasJSONItemObject.Create;
 try

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
         JSONTechniques.Merge(CurrentJSON,[TPasJSONMergeFlag.ForceObjectPropertyValueDestinationType]);
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

  TpvJSONUtils.ResolveTemplates(JSONTechniques);

  BaseJSONItem:=JSONTechniques.Properties['techniques'];

  if assigned(BaseJSONItem) then begin

   TpvJSONUtils.ResolveInheritances(BaseJSONItem);

   if BaseJSONItem is TPasJSONItemObject then begin

    BaseJSONItemObject:=TPasJSONItemObject(BaseJSONItem);

    for JSONItemObjectProperty in BaseJSONItemObject do begin
     if (length(JSONItemObjectProperty.Key)>0) and
        assigned(JSONItemObjectProperty.Value) and
        (JSONItemObjectProperty.Value is TPasJSONItemObject) then begin
      Technique:=TTechnique.Create(self);
      try
       Technique.fName:=JSONItemObjectProperty.Key;
      finally
       fTechniques.Add(Technique);
      end;
      fTechniqueNameMap.Add(Technique.fName,Technique);
     end;
    end;

    for JSONItemObjectProperty in BaseJSONItemObject do begin
     if (length(JSONItemObjectProperty.Key)>0) and
        assigned(JSONItemObjectProperty.Value) and
        (JSONItemObjectProperty.Value is TPasJSONItemObject) then begin
      Technique:=fTechniqueNameMap[JSONItemObjectProperty.Key];
      if assigned(Technique) then begin
       Technique.LoadFromJSONObject(TPasJSONItemObject(JSONItemObjectProperty.Value));
      end;
     end;
    end;

   end;

  end;


 finally
  FreeAndNil(JSONTechniques);
 end;

end;

destructor TpvTechniques.Destroy;
begin

 FreeAndNil(fTechniqueNameMap);

 FreeAndNil(fTechniques);

 FreeAndNil(fShaderNameMap);

 FreeAndNil(fShaders);

 inherited Destroy;

end;

end.