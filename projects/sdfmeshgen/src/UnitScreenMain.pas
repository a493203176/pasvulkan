unit UnitScreenMain;
{$ifdef fpc}
 {$mode delphi}
 {$ifdef cpu386}
  {$asmmode intel}
 {$endif}
 {$ifdef cpuamd64}
  {$asmmode intel}
 {$endif}
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$if defined(Win32) or defined(Win64)}
 {$define Windows}
{$ifend}

interface

uses SysUtils,
     Classes,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application,
     PasVulkan.Sprites,
     PasVulkan.Canvas,
     PasVulkan.GUI,
     PasVulkan.Font,
     PasVulkan.TrueTypeFont,
     PasVulkan.TextEditor;

type TScreenMain=class(TpvApplicationScreen)
      private
       fVulkanGraphicsCommandPool:TpvVulkanCommandPool;
       fVulkanGraphicsCommandBuffer:TpvVulkanCommandBuffer;
       fVulkanGraphicsCommandBufferFence:TpvVulkanFence;
       fVulkanTransferCommandPool:TpvVulkanCommandPool;
       fVulkanTransferCommandBuffer:TpvVulkanCommandBuffer;
       fVulkanTransferCommandBufferFence:TpvVulkanFence;
       fVulkanRenderPass:TpvVulkanRenderPass;
       fVulkanCommandPool:TpvVulkanCommandPool;
       fVulkanRenderCommandBuffers:array[0..MaxSwapChainImages-1] of TpvVulkanCommandBuffer;
       fVulkanRenderSemaphores:array[0..MaxSwapChainImages-1] of TpvVulkanSemaphore;
       fVulkanCanvas:TpvCanvas;
       fScreenToCanvasScale:TpvVector2;
       fGUIInstance:TpvGUIInstance;
       fGUIRootPanel:TpvGUIPanel;
       fGUIWindow:TpvGUIWindow;
       fGUILabel:TpvGUILabel;
       fGUIButton:TpvGUIButton;
       fGUITextEdit:TpvGUITextEdit;
       fGUIOtherWindow:TpvGUIWindow;
       fGUIYetOtherWindow:TpvGUIWindow;
       fLastMousePosition:TpvVector2;
       fLastMouseButtons:TpvApplicationInputPointerButtons;
       fReady:boolean;
       fTerminationMessageDialogVisible:boolean;
       fTime:TpvDouble;
       procedure OnTerminationMessageDialogButtonClick(const aSender:TpvGUIObject;const aID:TpvInt32);
       procedure OnTerminationMessageDialogDestroy(const aSender:TpvGUIObject);
       procedure ShowTerminationMessageDialogDestroy(const aSender:TpvGUIObject);
       procedure Button0OnClick(const aSender:TpvGUIObject);
      public

       constructor Create; override;

       destructor Destroy; override;

       procedure Show; override;

       procedure Hide; override;

       procedure Resume; override;

       procedure Pause; override;

       procedure Resize(const aWidth,aHeight:TpvInt32); override;

       procedure AfterCreateSwapChain; override;

       procedure BeforeDestroySwapChain; override;

       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; override;

       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; override;

       function Scrolled(const aRelativeAmount:TpvVector2):boolean; override;

       function CanBeParallelProcessed:boolean; override;

       procedure Check(const aDeltaTime:TpvDouble); override;

       procedure Update(const aDeltaTime:TpvDouble); override;

       procedure Draw(const aSwapChainImageIndex:TpvInt32;var aWaitSemaphore:TpvVulkanSemaphore;const aWaitFence:TpvVulkanFence=nil); override;

     end;

implementation

constructor TScreenMain.Create;
begin
 inherited Create;
 fReady:=false;
 fTerminationMessageDialogVisible:=false;
 fTime:=0.48;
 fLastMousePosition:=TpvVector2.Null;
 fLastMouseButtons:=[];
end;

destructor TScreenMain.Destroy;
begin
 inherited Destroy;
end;

procedure TScreenMain.Button0OnClick(const aSender:TpvGUIObject);
begin

 TpvGUIMessageDialog.Create(fGUIInstance,
                            'Question',
                            'Do you like this GUI?',
                            [TpvGUIMessageDialogButton.Create(0,'Yes',KEYCODE_RETURN,fGUIInstance.Skin.IconThumbUp,24.0),
                             TpvGUIMessageDialogButton.Create(1,'No',KEYCODE_ESCAPE,fGUIInstance.Skin.IconThumbDown,24.0)],
                            fGUIInstance.Skin.IconDialogQuestion);

end;

procedure TScreenMain.Show;
var Index:TpvInt32;
    WindowMenu:TpvGUIWindowMenu;
    MenuItem:TpvGUIMenuItem;
    PopupMenu:TpvGUIPopupMenu;
//    Popup:TpvGUIPopup;
    Panel:TpvGUIPanel;
    Window:TpvGUIWindow;
    IntegerEdit:TpvGUIIntegerEdit;
    FloatEdit:TpvGUIFloatEdit;
    ScrollBar:TpvGUIScrollBar;
    Slider:TpvGUISlider;
    ScrollPanel:TpvGUIScrollPanel;
    TabPanel:TpvGUITabPanel;
begin

 inherited Show;

 pvApplication.VisibleMouseCursor:=false;

 fVulkanGraphicsCommandPool:=TpvVulkanCommandPool.Create(pvApplication.VulkanDevice,
                                                         pvApplication.VulkanDevice.GraphicsQueueFamilyIndex,
                                                         TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));

 fVulkanGraphicsCommandBuffer:=TpvVulkanCommandBuffer.Create(fVulkanGraphicsCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanGraphicsCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fVulkanTransferCommandPool:=TpvVulkanCommandPool.Create(pvApplication.VulkanDevice,
                                                         pvApplication.VulkanDevice.TransferQueueFamilyIndex,
                                                         TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));

 fVulkanTransferCommandBuffer:=TpvVulkanCommandBuffer.Create(fVulkanTransferCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);

 fVulkanTransferCommandBufferFence:=TpvVulkanFence.Create(pvApplication.VulkanDevice);

 fVulkanCommandPool:=TpvVulkanCommandPool.Create(pvApplication.VulkanDevice,
                                                 pvApplication.VulkanDevice.GraphicsQueueFamilyIndex,
                                                 TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
 for Index:=0 to MaxSwapChainImages-1 do begin
  fVulkanRenderCommandBuffers[Index]:=TpvVulkanCommandBuffer.Create(fVulkanCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);
  fVulkanRenderSemaphores[Index]:=TpvVulkanSemaphore.Create(pvApplication.VulkanDevice);
 end;

 fVulkanRenderPass:=nil;

 fVulkanCanvas:=TpvCanvas.Create(pvApplication.VulkanDevice,
                                 pvApplication.VulkanDevice.GraphicsQueue,
                                 fVulkanGraphicsCommandBuffer,
                                 fVulkanGraphicsCommandBufferFence,
                                 pvApplication.VulkanDevice.TransferQueue,
                                 fVulkanTransferCommandBuffer,
                                 fVulkanTransferCommandBufferFence,
                                 pvApplication.VulkanPipelineCache,
                                 MaxSwapChainImages);

 fGUIInstance:=TpvGUIInstance.Create(pvApplication.VulkanDevice,fVulkanCanvas);

 fGUIInstance.Width:=pvApplication.Width;
 fGUIInstance.Height:=pvApplication.Height;

 begin
  WindowMenu:=fGUIInstance.AddMenu;

  MenuItem:=TpvGUIMenuItem.Create(WindowMenu);
  MenuItem.Caption:='File';

  begin
   PopupMenu:=TpvGUIPopupMenu.Create(MenuItem);

   MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
   MenuItem.Icon:=fGUIInstance.Skin.IconContentDelete;
   MenuItem.IconHeight:=12;
   MenuItem.Caption:='New';
   MenuItem.ShortcutHint:='Shift+Ctrl+N';

   MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
   MenuItem.Icon:=fGUIInstance.Skin.IconContentPaste;
   MenuItem.IconHeight:=12;
   MenuItem.Caption:='Open';
   MenuItem.ShortcutHint:='Ctrl+O';

   MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
   MenuItem.Icon:=fGUIInstance.Skin.IconContentCopy;
   MenuItem.IconHeight:=12;
   MenuItem.Caption:='Save';
   MenuItem.ShortcutHint:='Ctrl+S';

   MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
   MenuItem.Icon:=fGUIInstance.Skin.IconContentCopy;
   MenuItem.IconHeight:=12;
   MenuItem.Caption:='Save as';
   MenuItem.ShortcutHint:='Shift+Ctrl+S';

   MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
   MenuItem.Caption:='-';

   MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
   MenuItem.Icon:=fGUIInstance.Skin.IconWindowClose;
   MenuItem.IconHeight:=12;
   MenuItem.Caption:='Exit';
   MenuItem.ShortcutHint:='Alt+F4';
   MenuItem.OnClick:=ShowTerminationMessageDialogDestroy;

  end;

 end;

 fGUIInstance.Content.Layout:=TpvGUIFillLayout.Create(fGUIInstance.Content,0.0);

 fGUIRootPanel:=TpvGUIPanel.Create(fGUIInstance.Content);
 fGUIRootPanel.Background:=true;
 fGUIRootPanel.Layout:=TpvGUIFillLayout.Create(fGUIRootPanel,8.0);

// fGUIInstance.Layout
(*fGUIWindow:=TpvGUIWindow.Create(fGUIInstance);
 fGUIWindow.Left:=50;
 fGUIWindow.Top:=400;
 fGUIWindow.Title:='Window with GridLayout';
 fGUIWindow.Content.Layout:=TpvGUIBoxLayout.Create(fGUIWindow.Content,TpvGUILayoutAlignment.Fill,TpvGUILayoutOrientation.Vertical,8.0,8.0);
 fGUIWindow.AddMinimizationButton;
 fGUIWindow.AddMaximizationButton;
 fGUIWindow.AddCloseButton;

 begin
  WindowMenu:=fGUIWindow.AddMenu;

  MenuItem:=TpvGUIMenuItem.Create(WindowMenu);
  MenuItem.Caption:='File';

  PopupMenu:=TpvGUIPopupMenu.Create(MenuItem);
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='New';
  MenuItem.ShortcutHint:='Ctrl-N';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='-';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Open';
  MenuItem.ShortcutHint:='Ctrl-O';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Open recent';
  MenuItem.ShortcutHint:='Shift-Ctrl-O';
  TpvGUIMenuItem.Create(TpvGUIPopupMenu.Create(MenuItem)).Caption:='Test';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='-';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Save';
  MenuItem.ShortcutHint:='Ctrl-S';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Save as';
  MenuItem.ShortcutHint:='Shift-Ctrl-S';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='-';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Exit';
  MenuItem.ShortcutHint:='Alt+F4';

  MenuItem:=TpvGUIMenuItem.Create(WindowMenu);
  MenuItem.Caption:='Edit';
  MenuItem.Enabled:=false;

  PopupMenu:=TpvGUIPopupMenu.Create(MenuItem);
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Undo';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Redo';

  MenuItem:=TpvGUIMenuItem.Create(WindowMenu);
  MenuItem.Caption:='Settings';

  PopupMenu:=TpvGUIPopupMenu.Create(MenuItem);
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Audio';
  MenuItem:=TpvGUIMenuItem.Create(PopupMenu);
  MenuItem.Caption:='Video';

  MenuItem:=TpvGUIMenuItem.Create(WindowMenu);
  MenuItem.Caption:='Help';
 end;

 Panel:=TPvGUIPanel.Create(fGUIWindow.Content);
 Panel.Layout:=TpvGUIGridLayout.Create(Panel,4,TpvGUILayoutAlignment.Leading,TpvGUILayoutAlignment.Middle,TpvGUILayoutOrientation.Horizontal,0.0,8.0,8.0);

 fGUILabel:=TpvGUILabel.Create(Panel);
 fGUILabel.Caption:='An example label';
 fGUILabel.Cursor:=TpvGUICursor.Link;

{fGUIButton:=TpvGUIButton.Create(fGUIWindow.ButtonPanel);
 fGUIButton.Caption:=TpvRawByteString(#$e2#$80#$a6);}

 fGUIButton:=TpvGUIButton.Create(Panel);
 fGUIButton.Caption:='An example button';
 fGUIButton.OnClick:=Button0OnClick;

 fGUIButton:=TpvGUIToggleButton.Create(Panel);
 fGUIButton.Caption:='An example toggle button';

 fGUIButton:=TpvGUIButton.Create(Panel);
 fGUIButton.Caption:='An example disabled button';
 fGUIButton.Enabled:=false;

 fGUITextEdit:=TpvGUITextEdit.Create(fGUIWindow.Content);
 fGUITextEdit.Text:='An example text edit';
 fGUITextEdit.TextHorizontalAlignment:=TpvGUITextAlignment.Leading;
 fGUITextEdit.MinimumWidth:=320;
 fGUITextEdit.MinimumHeight:=32;
 fGUITextEdit.Enabled:=true;

 IntegerEdit:=TpvGUIIntegerEdit.Create(fGUIWindow.Content);
 IntegerEdit.Value:=1337;
 IntegerEdit.TextHorizontalAlignment:=TpvGUITextAlignment.Leading;
 IntegerEdit.MinimumWidth:=320;
 IntegerEdit.MinimumHeight:=32;
 IntegerEdit.Enabled:=true;

 FloatEdit:=TpvGUIFloatEdit.Create(fGUIWindow.Content);
 FloatEdit.Value:=PI;
 FloatEdit.TextHorizontalAlignment:=TpvGUITextAlignment.Leading;
 FloatEdit.MinimumWidth:=320;
 FloatEdit.MinimumHeight:=32;
 FloatEdit.Enabled:=true;

{Popup:=TpvGUIPopup.Create(fGUITextEdit);
 Popup.FixedSize.Vector:=TpvVector2.Create(160,100);
 Popup.AnchorSide:=TpvGUIPopupAnchorSide.Bottom;}

 fGUIOtherWindow:=TpvGUIWindow.Create(fGUIInstance);
 fGUIOtherWindow.Left:=550;
 fGUIOtherWindow.Top:=50;
 fGUIOtherWindow.Title:='Window with BoxLayout';
 fGUIOtherWindow.Content.Layout:=TpvGUIBoxLayout.Create(fGUIOtherWindow.Content,TpvGUILayoutAlignment.Leading,TpvGUILayoutOrientation.Vertical,8.0,8.0);
 fGUIOtherWindow.AddMinimizationButton;
 fGUIOtherWindow.AddMaximizationButton;
 fGUIOtherWindow.AddCloseButton;

 Panel:=TPvGUIPanel.Create(fGUIOtherWindow.Content);
 Panel.Layout:=TpvGUIGridLayout.Create(Panel,4,TpvGUILayoutAlignment.Leading,TpvGUILayoutAlignment.Middle,TpvGUILayoutOrientation.Horizontal,0.0,8.0,8.0);

 fGUILabel:=TpvGUILabel.Create(Panel);
 fGUILabel.Caption:='An other example label';
 fGUILabel.Cursor:=TpvGUICursor.Busy;

 fGUILabel:=TpvGUILabel.Create(Panel);
 fGUILabel.Caption:='An another example label';
 fGUILabel.Cursor:=TpvGUICursor.Unavailable;

 fGUILabel:=TpvGUILabel.Create(Panel);
 fGUILabel.Caption:='Yet another example label';
 fGUILabel.Cursor:=TpvGUICursor.Pen;

 fGUILabel:=TpvGUILabel.Create(Panel);
 fGUILabel.Caption:='Again another example label';
 fGUILabel.Cursor:=TpvGUICursor.Link;

 TpvGUICheckBox.Create(Panel).Caption:='Check box';

 TpvGUIRadioCheckBox.Create(Panel).Caption:='Radio check box (0)';

 TpvGUIRadioCheckBox.Create(Panel).Caption:='Radio check box (1)';

 TpvGUIRadioCheckBox.Create(Panel).Caption:='Radio check box (2)';

 fGUIButton:=TpvGUIRadioButton.Create(Panel);
 fGUIButton.Caption:='Radio button (0)';

 fGUIButton:=TpvGUIRadioButton.Create(Panel);
 fGUIButton.Caption:='Radio button (1)';

 fGUIButton:=TpvGUIRadioButton.Create(Panel);
 fGUIButton.Caption:='Radio button (2)';

 fGUIButton:=TpvGUIRadioButton.Create(Panel);
 fGUIButton.Caption:='Radio button (3)';

 fGUIYetOtherWindow:=TpvGUIWindow.Create(fGUIInstance);
 fGUIYetOtherWindow.Left:=750;
 fGUIYetOtherWindow.Top:=350;
 fGUIYetOtherWindow.Title:='Window with FillLayout and ScrollPanel';
 fGUIYetOtherWindow.Content.Layout:=TpvGUIFillLayout.Create(fGUIOtherWindow.Content,0.0);
 fGUIYetOtherWindow.AddMinimizationButton;
 fGUIYetOtherWindow.AddMaximizationButton;
 fGUIYetOtherWindow.AddCloseButton;

 ScrollPanel:=TpvGUIScrollPanel.Create(fGUIYetOtherWindow.Content);
 ScrollPanel.Content.Layout:=TpvGUIBoxLayout.Create(ScrollPanel.Content,TpvGUILayoutAlignment.Leading,TpvGUILayoutOrientation.Vertical,8.0,8.0);

 fGUIButton:=TpvGUIToggleButton.Create(ScrollPanel.Content);
 fGUIButton.Caption:='Toggle button';
 fGUIButton.FixedWidth:=480;
 fGUIButton.FixedHeight:=240;
  *)

end;

procedure TScreenMain.Hide;
var Index:TpvInt32;
begin
 FreeAndNil(fGUIInstance);
 FreeAndNil(fVulkanCanvas);
 FreeAndNil(fVulkanRenderPass);
 for Index:=0 to MaxSwapChainImages-1 do begin
  FreeAndNil(fVulkanRenderCommandBuffers[Index]);
  FreeAndNil(fVulkanRenderSemaphores[Index]);
 end;
 FreeAndNil(fVulkanCommandPool);
 FreeAndNil(fVulkanTransferCommandBufferFence);
 FreeAndNil(fVulkanTransferCommandBuffer);
 FreeAndNil(fVulkanTransferCommandPool);
 FreeAndNil(fVulkanGraphicsCommandBufferFence);
 FreeAndNil(fVulkanGraphicsCommandBuffer);
 FreeAndNil(fVulkanGraphicsCommandPool);
 pvApplication.VisibleMouseCursor:=true;
 inherited Hide;
end;

procedure TScreenMain.Resume;
begin
 inherited Resume;
end;

procedure TScreenMain.Pause;
begin
 inherited Pause;
end;

procedure TScreenMain.Resize(const aWidth,aHeight:TpvInt32);
begin
 inherited Resize(aWidth,aHeight);
end;

procedure TScreenMain.AfterCreateSwapChain;
var SwapChainImageIndex:TpvInt32;
begin
 inherited AfterCreateSwapChain;

 FreeAndNil(fVulkanRenderPass);

 fVulkanRenderPass:=TpvVulkanRenderPass.Create(pvApplication.VulkanDevice);

 fVulkanRenderPass.AddSubpassDescription(0,
                                         VK_PIPELINE_BIND_POINT_GRAPHICS,
                                         [],
                                         [fVulkanRenderPass.AddAttachmentReference(fVulkanRenderPass.AddAttachmentDescription(0,
                                                                                                                              pvApplication.VulkanSwapChain.ImageFormat,
                                                                                                                              VK_SAMPLE_COUNT_1_BIT,
                                                                                                                              VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                                              VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                                              VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                                              VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                                              VK_IMAGE_LAYOUT_UNDEFINED, //VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, //VK_IMAGE_LAYOUT_UNDEFINED, // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                                                                                                              VK_IMAGE_LAYOUT_PRESENT_SRC_KHR //VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL //VK_IMAGE_LAYOUT_PRESENT_SRC_KHR  // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                                                                             ),
                                                                             VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                            )],
                                         [],
                                         fVulkanRenderPass.AddAttachmentReference(fVulkanRenderPass.AddAttachmentDescription(0,
                                                                                                                             pvApplication.VulkanDepthImageFormat,
                                                                                                                             VK_SAMPLE_COUNT_1_BIT,
                                                                                                                             VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                                             VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                                             VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                                             VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                                             VK_IMAGE_LAYOUT_UNDEFINED, //VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, // VK_IMAGE_LAYOUT_UNDEFINED, // VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                                                                                                             VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                                                                            ),
                                                                                  VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                                 ),
                                         []);
 fVulkanRenderPass.AddSubpassDependency(VK_SUBPASS_EXTERNAL,
                                        0,
                                        TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                        TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                                        TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT),
                                        TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
                                        TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT));
 fVulkanRenderPass.AddSubpassDependency(0,
                                        VK_SUBPASS_EXTERNAL,
                                        TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                                        TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                        TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
                                        TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT),
                                        TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT));
 fVulkanRenderPass.Initialize;

 fVulkanRenderPass.ClearValues[0].color.float32[0]:=0.0;
 fVulkanRenderPass.ClearValues[0].color.float32[1]:=0.0;
 fVulkanRenderPass.ClearValues[0].color.float32[2]:=0.0;
 fVulkanRenderPass.ClearValues[0].color.float32[3]:=1.0;

 fVulkanCanvas.VulkanRenderPass:=fVulkanRenderPass;
 fVulkanCanvas.CountBuffers:=pvApplication.CountSwapChainImages;
 if pvApplication.Width<pvApplication.Height then begin
  fVulkanCanvas.Width:=(720*pvApplication.Width) div pvApplication.Height;
  fVulkanCanvas.Height:=720;
 end else begin
  fVulkanCanvas.Width:=1280;
  fVulkanCanvas.Height:=(1280*pvApplication.Height) div pvApplication.Width;
 end;
 fVulkanCanvas.Viewport.x:=0;
 fVulkanCanvas.Viewport.y:=0;
 fVulkanCanvas.Viewport.width:=pvApplication.Width;
 fVulkanCanvas.Viewport.height:=pvApplication.Height;
 fScreenToCanvasScale:=TpvVector2.Create(fVulkanCanvas.Width,fVulkanCanvas.Height)/TpvVector2.Create(pvApplication.Width,pvApplication.Height);

 for SwapChainImageIndex:=0 to length(fVulkanRenderCommandBuffers)-1 do begin
  FreeAndNil(fVulkanRenderCommandBuffers[SwapChainImageIndex]);
  fVulkanRenderCommandBuffers[SwapChainImageIndex]:=TpvVulkanCommandBuffer.Create(fVulkanCommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);
 end;

 fGUIInstance.VulkanRenderPass:=fVulkanRenderPass;
 fGUIInstance.CountBuffers:=pvApplication.CountSwapChainImages;
 fGUIInstance.Width:=fVulkanCanvas.Width;
 fGUIInstance.Height:=fVulkanCanvas.Height;
 fGUIInstance.MousePosition:=TpvVector2.Create(fGUIInstance.Width*0.5,fGUIInstance.Height*0.5);

 pvApplication.Input.SetCursorPosition(pvApplication.Width div 2,pvApplication.Height div 2);

 fGUIInstance.AfterCreateSwapChain;

 fGUIInstance.PerformLayout;

end;

procedure TScreenMain.BeforeDestroySwapChain;
begin
 fGUIInstance.BeforeDestroySwapChain;
 fVulkanCanvas.VulkanRenderPass:=nil;
 FreeAndNil(fVulkanRenderPass);
 inherited BeforeDestroySwapChain;
end;

procedure TScreenMain.OnTerminationMessageDialogButtonClick(const aSender:TpvGUIObject;const aID:TpvInt32);
begin
 if aID=0 then begin
  pvApplication.Terminate;
 end;
end;

procedure TScreenMain.OnTerminationMessageDialogDestroy(const aSender:TpvGUIObject);
begin
 fTerminationMessageDialogVisible:=false;
end;

procedure TScreenMain.ShowTerminationMessageDialogDestroy(const aSender:TpvGUIObject);
var MessageDialog:TpvGUIMessageDialog;
begin
 if not fTerminationMessageDialogVisible then begin
  fTerminationMessageDialogVisible:=true;
  MessageDialog:=TpvGUIMessageDialog.Create(fGUIInstance,
                                            'Question',
                                            'Do you really want to quit this application?',
                                            [TpvGUIMessageDialogButton.Create(0,'Yes',KEYCODE_RETURN,fGUIInstance.Skin.IconThumbUp,24.0),
                                             TpvGUIMessageDialogButton.Create(1,'No',KEYCODE_ESCAPE,fGUIInstance.Skin.IconThumbDown,24.0)],
                                            fGUIInstance.Skin.IconDialogQuestion);
  MessageDialog.OnButtonClick:=OnTerminationMessageDialogButtonClick;
  MessageDialog.OnDestroy:=OnTerminationMessageDialogDestroy;
 end;
end;

function TScreenMain.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
begin
 result:=false;
 if fReady and not fGUIInstance.KeyEvent(aKeyEvent) then begin
  if aKeyEvent.KeyEventType=TpvApplicationInputKeyEventType.Down then begin
   case aKeyEvent.KeyCode of
    KEYCODE_QUIT,KEYCODE_F4:begin
     if (aKeyEvent.KeyCode=KEYCODE_QUIT) or
        ((aKeyEvent.KeyCode=KEYCODE_F4) and
         ((aKeyEvent.KeyModifiers*[TpvApplicationInputKeyModifier.ALT,
                                   TpvApplicationInputKeyModifier.CTRL,
                                   TpvApplicationInputKeyModifier.SHIFT,
                                   TpvApplicationInputKeyModifier.META])=[TpvApplicationInputKeyModifier.ALT])) then begin
      ShowTerminationMessageDialogDestroy(nil);
      result:=true;
     end;
    end;
   end;
  end;
 end;
end;

function TScreenMain.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
var Index:TpvInt32;
    cy:TpvFloat;
    LocalPointerEvent:TpvApplicationInputPointerEvent;
begin
 result:=false;
 if fReady then begin
  LocalPointerEvent:=aPointerEvent;
  LocalPointerEvent.Position:=LocalPointerEvent.Position*fScreenToCanvasScale;
  LocalPointerEvent.RelativePosition:=LocalPointerEvent.RelativePosition*fScreenToCanvasScale;
  if not fGUIInstance.PointerEvent(LocalPointerEvent) then begin
  end;
 end;
 case aPointerEvent.PointerEventType of
  TpvApplicationInputPointerEventType.Down:begin
   Include(fLastMouseButtons,aPointerEvent.Button);
   fLastMousePosition:=aPointerEvent.Position*fScreenToCanvasScale;
  end;
  TpvApplicationInputPointerEventType.Up:begin
   Exclude(fLastMouseButtons,aPointerEvent.Button);
   fLastMousePosition:=aPointerEvent.Position*fScreenToCanvasScale;
  end;
  TpvApplicationInputPointerEventType.Motion:begin
   fLastMousePosition:=aPointerEvent.Position*fScreenToCanvasScale;
  end;
 end;
end;

function TScreenMain.Scrolled(const aRelativeAmount:TpvVector2):boolean;
begin
 if fReady then begin
  result:=fGUIInstance.Scrolled(fLastMousePosition,aRelativeAmount);
 end else begin
  result:=false;
 end;
end;

function TScreenMain.CanBeParallelProcessed:boolean;
begin
 result:=true;
end;

procedure TScreenMain.Check(const aDeltaTime:TpvDouble);
begin

 inherited Check(aDeltaTime);

 fGUIInstance.UpdateBufferIndex:=pvApplication.UpdateSwapChainImageIndex;
 fGUIInstance.DeltaTime:=aDeltaTime;
 fGUIInstance.Check;

end;

procedure TScreenMain.Update(const aDeltaTime:TpvDouble);
const BoolToInt:array[boolean] of TpvInt32=(0,1);
      Options:array[0..0] of string=('Back');
var Index:TpvInt32;
    cy:TpvFloat;
    s:string;
    IsSelected:boolean;
begin
 inherited Update(aDeltaTime);

 fVulkanCanvas.Start(pvApplication.UpdateSwapChainImageIndex);

 fVulkanCanvas.ViewMatrix:=TpvMatrix4x4.Identity;

 fVulkanCanvas.BlendingMode:=TpvCanvasBlendingMode.AlphaBlending;

{$if false}
 fVulkanCanvas.Color:=TpvVector4.Create(IfThen(TpvApplicationInputPointerButton.Left in fLastMouseButtons,1.0,0.0),
                                        IfThen(TpvApplicationInputPointerButton.Right in fLastMouseButtons,1.0,0.0),
                                        1.0,
                                        1.0);
 fVulkanCanvas.DrawFilledCircle(fLastMousePosition,16.0);
 fVulkanCanvas.Color:=TpvVector4.Create(0.5,1.0,0.5,1.0);
 fVulkanCanvas.DrawFilledCircle(fLastMousePosition,4.0);
 fVulkanCanvas.Color:=TpvVector4.Create(1.0,1.0,1.0,1.0);
{$ifend}

 fGUIInstance.DrawWidgetBounds:=false;
 fGUIInstance.UpdateBufferIndex:=pvApplication.UpdateSwapChainImageIndex;
 fGUIInstance.DeltaTime:=aDeltaTime;
 fGUIInstance.Update;
 fGUIInstance.Draw;

 fVulkanCanvas.Stop;

 fTime:=fTime+aDeltaTime;

 fReady:=true;
end;

procedure TScreenMain.Draw(const aSwapChainImageIndex:TpvInt32;var aWaitSemaphore:TpvVulkanSemaphore;const aWaitFence:TpvVulkanFence=nil);
const Offsets:array[0..0] of TVkDeviceSize=(0);
var VulkanCommandBuffer:TpvVulkanCommandBuffer;
    VulkanSwapChain:TpvVulkanSwapChain;
begin

 begin

  begin

   VulkanCommandBuffer:=fVulkanRenderCommandBuffers[aSwapChainImageIndex];
   VulkanSwapChain:=pvApplication.VulkanSwapChain;

   fGUIInstance.DrawBufferIndex:=pvApplication.DrawSwapChainImageIndex;
   fGUIInstance.ExecuteDraw(aWaitSemaphore);

   VulkanCommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));

   VulkanCommandBuffer.BeginRecording(TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT));

   fVulkanCanvas.ExecuteUpload(VulkanCommandBuffer,
                               pvApplication.DrawSwapChainImageIndex);

   fVulkanRenderPass.BeginRenderPass(VulkanCommandBuffer,
                                     pvApplication.VulkanFrameBuffers[aSwapChainImageIndex],
                                     VK_SUBPASS_CONTENTS_INLINE,
                                     0,
                                     0,
                                     VulkanSwapChain.Width,
                                     VulkanSwapChain.Height);

   fVulkanCanvas.ExecuteDraw(VulkanCommandBuffer,
                             pvApplication.DrawSwapChainImageIndex);

   fVulkanRenderPass.EndRenderPass(VulkanCommandBuffer);

   VulkanCommandBuffer.EndRecording;

   VulkanCommandBuffer.Execute(pvApplication.VulkanDevice.GraphicsQueue,
                               TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                               aWaitSemaphore,
                               fVulkanRenderSemaphores[aSwapChainImageIndex],
                               aWaitFence,
                               false);

   aWaitSemaphore:=fVulkanRenderSemaphores[aSwapChainImageIndex];

  end;

 end;

end;

end.
