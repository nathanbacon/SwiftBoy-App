//
//  Renderer.swift
//  GB
//
//  Created by Nathan Gelman on 7/30/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

import Foundation
import MetalKit

class GBRenderer: NSObject {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var textureLoader: MTKTextureLoader
    var gameboy: GameBoy
    
    var data: Data
    
    let vertices = [
        Vertex(position: float3(-1,1,0), texture: float2(0, 0)), // top left
        Vertex(position: float3(-1,-1,0), texture: float2(0, 1)), // bottom left
        Vertex(position: float3(1,-1,0), texture: float2(1, 1)), // bottom right
        Vertex(position: float3(1,1,0), texture: float2(1, 0)) // top right
    ]
    
    var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    var vertexDescriptor: MTLVertexDescriptor = {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<float3>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        return vertexDescriptor
    }()
    
    let textureDescriptor: MTLTextureDescriptor = {
       let textureDescriptor = MTLTextureDescriptor()
        
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = 160
        textureDescriptor.height = 144
        
        return textureDescriptor
    }()
    
    let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: 160, height: 144, depth: 1))
    
    struct Constants {
        var animateBy: Float = 0.0
    }
    
    struct Vertex {
        var position: float3
        var texture: float2
    }
    
    var constants = Constants()
    
    init(device: MTLDevice, gameboy: GameBoy) {
        self.device = device
        self.gameboy = gameboy
        
        textureLoader = MTKTextureLoader(device: device)
        data = Data(repeating: 0, count: 160*144*4)
        
        commandQueue = device.makeCommandQueue()!
        super.init()
        
        buildModel()
        buildPipelineState()
        
    }
    
    private func buildModel() {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
    }
    
    private func buildPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "textured_fragment")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction  = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
}

extension GBRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(), let descriptor = view.currentRenderPassDescriptor,
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
            let pipelineState = pipelineState,
            let indexBuffer = indexBuffer,
            let drawable = view.currentDrawable else { return }
        
        commandEncoder.setRenderPipelineState(pipelineState)
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        //commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
        
        //let texture = try! textureLoader.newTexture(data: gameboy.nextFrame, options: [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft])
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        
        texture?.replace(region: region, mipmapLevel: 0, withBytes: (gameboy.nextFrame as NSData).bytes, bytesPerRow: 160*4)
        
        commandEncoder.setFragmentTexture(texture, index: 0)
        
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
