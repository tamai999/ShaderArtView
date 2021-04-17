#include <metal_stdlib>
using namespace metal;

#import "common.h"

fragment half4 circleShader(ColorInOut in [[ stage_in ]]) {
    float2 uv = in.texCoord;
    uv -= 0.5;
    // 縦方向でビューのアスペクト比を調整
    uv.y *= in.aspectRatio;
    // 左上(0,0)からの距離を取得
    float r = length(uv);
    
    // 中心から描画する点の角度を求める
    float theta = atan2(uv.y, uv.x);
    // sin関数で１周で５つの山谷を作ります
    float time = in.u_time / 10;
    float wave = sin(5 * theta + time);
    // 中心からの距離に、上記で作った波の値を小さめにして（0.02とかかけて）足しこみます。
    // これで中心からの距離が波の高さ分変わるので、星っぽくなります。
    r += wave * 0.02;
    
    // step()関数を使って、rが0.1以下なら 1.0、大きければ 0.0 に二値化
    half color = step(r, 0.1);
    // RGBA の順番。Redだけ色を指定する
    return half4(color, 0.0, 0.0, 1.0);
}

//
// たぷたぷアニメーション
//
fragment half4 taptapShader(ColorInOut in [[ stage_in ]]) {
    // １秒で60すすむカウンタ
    float time = in.u_time;
    // 中心が(0, 0)になるように座標変換
    float2 uv = in.texCoord - 0.5;
    // 縦方向でビューのアスペクト比を調整
    uv.y *= in.aspectRatio;

    // 中心から描画する点の角度を求める
    float theta = atan2(uv.y, uv.x);
    // 12秒で 0~2pi
    float angleSpeed1 = fmod(1.0, 720.0) / 720 * 2 * M_PI_F;
    // ５つの頂点を持つ波を作る
    float threshold1 = 0.004 * sin(5 * (theta + angleSpeed1));

    // 10秒で 0~2pi
    float angleSpeed2 = -fmod(time, 600) / 600 * 2 * M_PI_F;
    // ６つの頂点を持つ波を作る
    float threshold2 = 0.004 * sin(6 * (theta + angleSpeed2));

    // 基準とする中心から一定の距離(0.13)に、２つの波を足しこむ。
    float threshold = threshold1 + threshold2 + 0.13;
    // 中心からの距離が上記計算結果より大きければ1.0、小さければ0.0
    half color = step(length(uv), threshold);
    // 色はRGBで指定。緑を指定。
    if (color != 0.0) {
        return half4(0.0, color, 0.0, 1.0);
    } else {
        // 色づけない部分は透明にする
        return half4(0.0);
    }
}

//
// 画像波打ちアニメーション
//
fragment half4 waveShader(ColorInOut in [[ stage_in ]],
                          texture2d<half> texture [[ texture(0) ]]) {
    // 1秒に１すすむ値にする
    float time = in.u_time / 60;
    // 中心が(0, 0)になるように座標変換
    float2 uv = in.texCoord - 0.5;
    // 縦方向でビューのアスペクト比を調整
    uv.y *= in.aspectRatio;
    // 中心から描画する点の角度を求める
    float theta = atan2(uv.y, uv.x);
    // 中心から描画点までの距離
    float r = length(uv);
    // 中心からの距離に正弦波で算出した値を加える（背景画像の取得位置を変更する）
    r += sin(-r * 20 + time * 3) * 0.05;
    // 中心から上記で計算した距離の色を取得
    float2 distR = float2(r * cos(theta), r * sin(theta)) + 0.5;
    half4 colorSample = texture.sample(s, distR);
    
    return colorSample;
}

//
// スケルトンアニメーション
//
fragment half4 skeletonShader(ColorInOut in [[ stage_in ]]) {
    // 速度。小さくすると速くなる。(1~)
    float speed = 5.0;
    // 縞模様の角度。大きくすると斜めになる(0.0~)
    float angle = 5.0;
    // 色の濃さ。大きくすると白味が多くなる(~1.0)
    float brightness = 0.8;
    // 明暗の差。大きくすると明暗が大きくなる。(0.0~1.0)
    float strength = 0.2;
    // 波の量。大きくすると波の数が増える
    float wave = 5.0;
    
    float time = in.u_time / speed;
    float2 uv =  in.texCoord;
    uv.y *= in.aspectRatio;
    half color = sin(-uv.x * wave - (uv.y * angle) + time) * strength + brightness;
    return half4(color, color, color, 1.0);
}

//
// じわじわ広がる星
//
fragment half4 starBaseShader(ColorInOut in [[stage_in]])
{
    // 中心が(0, 0)になるように座標変換
    float2 uv = in.texCoord - 0.5;
    // 縦方向でビューのアスペクト比を調整
    uv.y *= in.aspectRatio;
    // 時間の正規化(0~2pi)。5秒で 0~360度
    float time = in.u_time / 300;
    // 中心から描画する点の角度を求める
    float theta = atan2(uv.y, uv.x);
    // 中心から描画点までの距離
    float r = length(uv);
    // 角度に応じて波を作る
    float wave = sin(theta * 5.0);
    // 中心からの距離に応じて波を繰り返す
    float color = sin(length(uv * 30.0) - time * 10 + r + wave) * 0.5 + 0.5;
    
    return half4(0.0, color, color, 1.0);
}

//
// オーロラにみえなくもない
//
fragment half4 auroraShader(ColorInOut in [[ stage_in ]]) {
    // 1秒に１すすむ値にする
    float time = in.u_time / 60;
    // 密度を高くして計算（より凝縮した画像にする）。倍率を上げればより俯瞰した感じの画像になる。
    float2 uv =  in.texCoord * 8.0;
    // 横方向に若干縦方向の要素を加えた波を作る
    float seed1 = sin(uv.x + uv.y * 0.1 + time);
    float seed2 = sin(uv.x + time * 1.5);
    // 青と赤に色を適当に作る
    float blue = sin(seed1 + time) * 0.5 + 0.0;  // 青は控えめ
    float green = sin(sin(seed1 + seed2) + time) * 0.5 + 0.5;    // 緑強め
    return half4(0.0, green, blue, 1.0);
}

//
// プールの底のようなアニメーション
// https://meganeunity.hateblo.jp/entry/2019/05/15/074607　を参考にさせてもらいました
//
float cellularnoise(float2 st,float n, float time) {
    st *= n;

    float2 ist = floor(st);
    float2 fst = fract(st);

    float distance = 5;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++){
            float2 neighbor = float2(x, y);
            float2 p = 0.5 + 0.5 * sin(time + 6.2831 * random(ist + neighbor));

            float2 diff = neighbor + p - fst;
            distance = min(distance, length(diff));
        }
    }

    return distance * 0.5;
}

fragment half4 kaiteiShader(ColorInOut in [[ stage_in ]]) {
    // 1秒に１すすむ値にする
    float time = in.u_time / 60;
    float waterSpeed = time * -0.02;

    float2 uv = in.texCoord;
    uv.y *= in.aspectRatio;
    uv.y += waterSpeed;

    float intency = cellularnoise(uv, 10, time);
    return pow(intency, 2) * half4(1, 1, 1, 0.0) + half4(0.0, 0.4, 1.0, 1.0);
}
