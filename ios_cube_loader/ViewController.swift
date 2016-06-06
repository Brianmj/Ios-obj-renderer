//
//  ViewController.swift
//  ios_cube_loader
//
//  Created by Brian Jones on 2/27/16.
//  Copyright © 2016 Brian Jones. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var library: MTLLibrary! = nil
    var mtlView: MTKView!    // set the view controller's view as a MTKView which will be assigned to mtlView later
    // var depthTexture: MTLTexture! = nil you do not need this as MTL creates it's own depth stencil texture
    
    var renderer: ObjRenderer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupMetal()
        setupView()
        //setupDepthTexture() no longer needed as metal view can create it's own depth stencil texture
        renderer = ObjRenderer(device: device)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func drawInMTKView(view: MTKView) {
        //
        
        let cb = commandQueue.commandBuffer()
        let rpd = view.currentRenderPassDescriptor
        let currentDrawable = view.currentDrawable
        
        rpd?.colorAttachments[0].loadAction = .Clear
        rpd?.colorAttachments[0].storeAction = .Store
        rpd?.colorAttachments[0].texture = currentDrawable?.texture
        rpd?.depthAttachment.loadAction = .Clear
        rpd?.depthAttachment.storeAction = .DontCare
        rpd?.depthAttachment.texture = view.depthStencilTexture
        
        
        
        let ce = cb.renderCommandEncoderWithDescriptor(rpd!)
        ce.endEncoding()
        
        
        cb.presentDrawable(currentDrawable!)
        cb.commit()
    }
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        // no operation
    }
    
    
    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.newCommandQueue()
        //library = device.newDefaultLibrary()
    }
    
    func setupView() {
        mtlView = view as? MTKView
        mtlView.device = device
        mtlView.delegate = self
        mtlView.colorPixelFormat = .BGRA8Unorm
        mtlView.clearColor = MTLClearColor(red: 0.3, green: 0.6, blue: 0.53, alpha: 1.0)
        mtlView.clearDepth = 1.0
        mtlView.depthStencilPixelFormat = .Depth32Float_Stencil8 // I guess setting this is where metal create it's own depth stencil texture
        
        mtlView.framebufferOnly = true
    }
    
    /*func setupDepthTexture() {
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.Depth32Float_Stencil8, width: Int(view.bounds.width), height: Int(view.bounds.height), mipmapped: false)
        depthTexture = device.newTextureWithDescriptor(depthTextureDescriptor)
    }*/
}

