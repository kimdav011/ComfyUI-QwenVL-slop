#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

IMAGE_COMFYUI_DIR="/opt/ComfyUI"
COMFYUI_DIR="/workspace/ComfyUI"
FILEBROWSER_CONFIG="/filebrowser/.config.json"
DB_FILE="/filebrowser/database/filebrowser.db"

bootstrap_runtime_comfyui() {
    echo "🔍 Checking runtime ComfyUI directory..."

    if [ ! -d "$IMAGE_COMFYUI_DIR" ]; then
        echo "❌ Missing baked ComfyUI directory: $IMAGE_COMFYUI_DIR"
        exit 1
    fi

    mkdir -p /workspace

    if [ ! -f "$COMFYUI_DIR/main.py" ]; then
        echo "📦 Bootstrapping ComfyUI into /workspace..."
        rm -rf "$COMFYUI_DIR"
        cp -a "$IMAGE_COMFYUI_DIR" "$COMFYUI_DIR"
    else
        echo "✅ Reusing existing ComfyUI in /workspace"
    fi

    mkdir -p /filebrowser/files
    ln -sfn "$COMFYUI_DIR" /filebrowser/files/ComfyUI
}

# Function to update custom nodes
update_nodes() {
    echo "🔄 Updating custom nodes..."
    cd /workspace/ComfyUI/custom_nodes

    # List of custom nodes to update
    nodes=(
        "https://github.com/ltdrdata/ComfyUI-Manager.git"
        "https://github.com/kijai/ComfyUI_essentials.git"
        "https://github.com/huchukato/comfy-tagcomplete.git"
        "https://github.com/huchukato/ComfyUI-QwenVL-Mod.git"
        "https://github.com/huchukato/ComfyUI-RIFE-TensorRT-Auto.git"
        "https://github.com/huchukato/ComfyUI-Upscaler-TensorRT-Auto.git"
        "https://github.com/huchukato/ComfyUI-HuggingFace.git"
        "https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git"
        "https://github.com/city96/ComfyUI-GGUF.git"
        "https://github.com/MoonGoblinDev/Civicomfy.git"
        "https://github.com/Koishi-Star/Euler-Smea-Dyn-Sampler.git"
        "https://github.com/ltdrdata/was-node-suite-comfyui.git"
        "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
        "https://github.com/rgthree/rgthree-comfy.git"
        "https://github.com/yolain/ComfyUI-Easy-Use.git"
        "https://github.com/kijai/ComfyUI-KJNodes.git"
        "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
        "https://github.com/Smirnov75/ComfyUI-mxToolkit.git"
        "https://github.com/princepainter/ComfyUI-PainterI2V.git"
        "https://github.com/princepainter/ComfyUI-PainterLongVideo.git"
        "https://github.com/ashtar1984/comfyui-find-perfect-resolution.git"
        "https://github.com/huchukato/ComfyUI-Selectors.git"
        "https://github.com/kijai/ComfyUI-MMAudio.git"
        "https://github.com/GACLove/ComfyUI-VFI.git"
        "https://github.com/stduhpf/ComfyUI-WanMoeKSampler.git"
        "https://github.com/melMass/comfy_mtb.git"
    )

    for node_url in "${nodes[@]}"; do
        node_name=$(basename "$node_url" .git)
        if [ -d "$node_name" ]; then
            echo "  🔄 Updating: $node_name"
            cd "$node_name"
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "  ⚠️ Failed to update $node_name"
            cd ..
        else
            echo "  📥 Installing: $node_name"
            git clone "$node_url" || echo "  ⚠️ Failed to clone $node_name"
        fi
    done

    # Install requirements for updated nodes
    echo "📦 Installing updated requirements..."
    bash -c 'for node_dir in */; do if [ -f "$node_dir/requirements.txt" ]; then echo "Installing requirements for $node_dir..." && /opt/comfyui-env/bin/pip install --no-cache-dir -r "$node_dir/requirements.txt" || echo "Failed to install requirements for $node_dir"; fi; done'

    echo "✅ Node update completed"
}

# Function to download latest workflows
update_workflows() {
    echo "🔄 Updating workflows from latest versions..."
    mkdir -p /workspace/ComfyUI/user/default/workflows
    cd /workspace/ComfyUI/user/default/workflows

    # List of latest workflows
    workflows=(
        "PMP-LoRaStack-Upscale-Wildcards.json"
        "WAN2.2-I2V-AutoPrompt-Story.json"
        "WAN2.2-T2V-I2V-AutoPrompt-Story.json"
        "WAN2.2-I2V-SVI-AutoPrompt-Story.json"
        "WAN2.2-I2V-AutoPrompt.json"
        "WAN2.2-I2V-AutoPrompt-GGUF.json"
        "WAN2.2-T2V-AutoPrompt.json"
        "WAN2.2-T2V-AutoPrompt-GGUF.json"
        "WAN2.2-I2V-SVI-AutoPrompt.json"
        "WAN2.2-I2V-SVI-AutoPrompt-GGUF.json"
        "WAN2.2-I2V-Full-AutoPrompt-MMAudio.json"
        "WAN2.2-I2V-Full-AutoPrompt-MMAudio-GGUF.json"
        "WAN2.2-T2V-I2V-Full-AutoPrompt-MMAudio-GGUF.json"
    )

    for workflow in "${workflows[@]}"; do
        echo "  📥 Downloading: $workflow"
        wget -q "https://github.com/huchukato/ComfyUI-QwenVL-Mod/raw/main/vastai/workflows/$workflow" -O "$workflow" || echo "  ⚠️ Failed to download $workflow"
    done

    echo "✅ Workflow update completed"
}

download_models() {
    echo "🔄 Downloading essential models..."
    cd /workspace/ComfyUI

    # Download VAE models
    if [ ! -f "/workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors" ]; then
        echo "  📥 Downloading WAN 2.1 VAE..."
        wget -q "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" -O "/workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors" || echo "  ⚠️ Failed to download WAN 2.1 VAE"
    fi

    if [ ! -f "/workspace/ComfyUI/models/vae/sdxl_vae.safetensors" ]; then
        echo "  📥 Downloading SDXL VAE..."
        wget -q "https://huggingface.co/huchukato/favs/resolve/main/VAE/sdxl.vae.safetensors" -O "/workspace/ComfyUI/models/vae/sdxl_vae.safetensors" || echo "  ⚠️ Failed to download SDXL VAE"
    fi

    # Download upscale models
    if [ ! -f "/workspace/ComfyUI/models/upscale_models/2xLexicaRRDBNet.pth" ]; then
        echo "  📥 Downloading 2xLexicaRRDBNet upscale model..."
        wget -q "https://huggingface.co/huchukato/favs/resolve/main/ESRGAN/2xLexicaRRDBNet.pth" -O "/workspace/ComfyUI/models/upscale_models/2xLexicaRRDBNet.pth" || echo "  ⚠️ Failed to download upscale model"
    fi

    if [ ! -f "/workspace/ComfyUI/models/upscale_models/2xLexicaRRDBNet_Sharp.pth" ]; then
        echo "  📥 Downloading 2xLexicaRRDBNet Sharp upscale model..."
        wget -q "https://huggingface.co/huchukato/favs/resolve/main/ESRGAN/2xLexicaRRDBNet_Sharp.pth" -O "/workspace/ComfyUI/models/upscale_models/2xLexicaRRDBNet_Sharp.pth" || echo "  ⚠️ Failed to download Sharp upscale model"
    fi

    # Download text encoder
    if [ ! -f "/workspace/ComfyUI/models/text_encoders/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" ]; then
        echo "  📥 Downloading NSFW WAN UMT5-XXL text encoder..."
        wget -q "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" -O "/workspace/ComfyUI/models/text_encoders/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" || echo "  ⚠️ Failed to download text encoder"
    fi

    echo "✅ Model download completed"
    echo "📋 Available models:"
    ls -la /workspace/ComfyUI/models/vae/
    ls -la /workspace/ComfyUI/models/upscale_models/
    ls -la /workspace/ComfyUI/models/text_encoders/
}

echo "🚀 Starting ComfyUI-QwenVL-Mod on RunPod (Full Version)"
echo "🎬 WAN 2.2 workflows ready"
echo "🌐 Multilingual support enabled"
echo "🎨 Visual style detection ready"
echo "⚡ GGUF backend optimized"
echo ""

bootstrap_runtime_comfyui

# Update workflows to latest versions
update_workflows

# Update custom nodes to latest versions
update_nodes

# Download essential models
download_models

echo "🔧 Services starting:"
echo "📁 FileBrowser: http://0.0.0.0:8080"
echo "📓 Jupyter Lab:  http://0.0.0.0:8888 (Terminal included)"
echo "🎨 ComfyUI:    http://0.0.0.0:8188"
echo "📋 Available workflows:"
ls -la /workspace/ComfyUI/user/default/workflows/
echo ""
echo "💡 Models pre-loaded for immediate use"
echo ""

# Start FileBrowser
echo "🔧 Starting FileBrowser..."
nohup /usr/local/bin/start-filebrowser.sh &> /filebrowser.log &
echo "✅ FileBrowser started"

# Start Jupyter Lab
echo "🔧 Starting Jupyter Lab..."
nohup /usr/local/bin/start-jupyter.sh &> /jupyter.log &
sleep 5
echo "🔍 Checking Jupyter Lab status..."
if pgrep -f "jupyter lab" > /dev/null; then
    echo "✅ Jupyter Lab started successfully"
    echo "📊 Jupyter Lab logs:"
    tail -10 /jupyter.log
else
    echo "❌ Jupyter Lab failed to start"
    echo "📊 Full error logs:"
    cat /jupyter.log
    echo "🔍 Checking what went wrong..."
    echo "🐍 Python version in virtual env:"
    /opt/comfyui-env/bin/python --version
    echo "📦 Jupyter Lab version in virtual env:"
    /opt/comfyui-env/bin/jupyter lab --version
fi

# Start ComfyUI
echo "🚀 Starting ComfyUI..."
echo "🌐 ComfyUI will be available at: http://0.0.0.0:$(echo $COMFYUI_ARGS | grep -oP '(?<=--port\s)\d+' || echo '8188')"
echo "📓 Jupyter Lab Terminal: Open http://0.0.0.0:8888 → New → Terminal"
cd $COMFYUI_DIR
nohup /opt/comfyui-env/bin/python main.py $COMFYUI_ARGS &> /comfyui.log &
echo "✅ ComfyUI started"

# Tail the ComfyUI log
tail -f /comfyui.log
