import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var artView1: ShaderArtView!
    @IBOutlet weak var artView2: ShaderArtView!
    @IBOutlet weak var artView3: ShaderArtView!
    @IBOutlet weak var artView4: ShaderArtView!
    @IBOutlet weak var artView5: ShaderArtView!
    @IBOutlet weak var artView6: ShaderArtView!
    @IBOutlet weak var artView7: ShaderArtView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        artView1.setupView(shaderName: "taptapShader")
        artView2.setupView(shaderName: "circleShader")
        artView3.setupView(shaderName: "waveShader", imageName: "sampleImage")
        artView4.setupView(shaderName: "kaiteiShader")
        artView5.setupView(shaderName: "auroraShader")
        artView6.setupView(shaderName: "skeletonShader")
        artView7.setupView(shaderName: "starBaseShader")
    }
}

