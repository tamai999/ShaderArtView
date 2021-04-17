import UIKit
import MetalKit

class ShaderArtView: MTKView {
    // Metal 画像頂点座標(x,y), uv座標(u,v)
    private let kImagePlaneVertexData: [Float] = [
        -1.0, -1.0, 0.0, 1.0,
        1.0, -1.0, 1.0, 1.0,
        -1.0, 1.0, 0.0, 0.0,
        1.0, 1.0, 1.0, 0.0
    ]

    private let maxBuffersInFlight = 3
    // Uniformバッファは256バイトの倍数にする（このShaderArtViewでは絶対に256バイトだけど、拡張時のため）
    private let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100
    
    private var commandQueue: MTLCommandQueue!
    private var vertexBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    private var texture: MTLTexture!
    
    lazy private var inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    private var uniformBufferOffset = 0
    private var uniformBufferIndex = 0
    private var uniforms: UnsafeMutablePointer<Uniforms>!
    private var dynamicUniformBuffer: MTLBuffer!
    
    private var u_time: Float = 1.0
    private var aspectRatio: Float = 1.0
}

// MARK: - internal

extension ShaderArtView {
    func setupView(shaderName: String, imageName: String? = nil) {
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else { fatalError() }
        device = defaultDevice
        backgroundColor = UIColor.clear
        preferredFramesPerSecond = 60
        clearColor = .init(red: 1, green: 1, blue: 1, alpha: 1)

        // Metalセットアップ
        commandQueue = defaultDevice.makeCommandQueue()
        // 頂点座標バッファ確保＆頂点情報流し込み
        let vSize = kImagePlaneVertexData.count * MemoryLayout<Uniforms>.size
        vertexBuffer = defaultDevice.makeBuffer(bytes: kImagePlaneVertexData, length: vSize, options: [])
        // レンダーパイプライン初期化
        guard let library = defaultDevice.makeDefaultLibrary() else { fatalError() }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        
        descriptor.fragmentFunction = library.makeFunction(name: shaderName)
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat        
        pipelineState = try! defaultDevice.makeRenderPipelineState(descriptor: descriptor)
        
        // Uniformバッファを確保
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        guard let buffer = defaultDevice.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared]) else { fatalError()}
        dynamicUniformBuffer = buffer
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to: Uniforms.self, capacity: 1)
        
        delegate = self
        
        // テクスチャを読み込む
        let textureLoader = MTKTextureLoader(device: defaultDevice)
        let textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
        ]
        
        if let name = imageName {
            texture = try? textureLoader.newTexture(name: name,
                                                    scaleFactor: 1.0,
                                                    bundle: nil,
                                                    options: textureLoaderOptions)
        }
    }
}

// MARK: - MTKViewDelegate

extension ShaderArtView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 横に対する縦の割合
        aspectRatio = Float(size.height / size.width)
    }
    
    func draw(in view: MTKView) {
        // 処理遅延対策
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }
        
        // スレッドが指すUniformバッファの場所（オフセット）を決める
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        // Uniformバッファに時刻（カウンタ）設定
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
        uniforms[0].u_time = u_time
        uniforms[0].aspectRatio = aspectRatio
        u_time += 1

        // 描画
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: uniformBufferOffset, index: 1)
        if let texture = texture {
            renderEncoder.setFragmentTexture(texture, index: 0)
        }
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        guard let drawable = currentDrawable else { return }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
