# syntax=docker/dockerfile:1.4
# ComfyUI-QwenVL-Mod RunPod Worker
# Enhanced with WAN 2.2 workflows, multilingual support, and GGUF backend
# Optimized for RTX 5090 and professional video generation

FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV IMAGEIO_FFMPEG_EXE=/usr/bin/ffmpeg
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$PATH:$CUDA_HOME/bin
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64

# Install system dependencies (CUDA already included in base image)
RUN apt update && \
    apt install -y --no-install-recommends \
    git \
    make \
    wget \
    curl \
    unzip \
    pkg-config \
    ca-certificates \
    build-essential \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    libglx-mesa0 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ffmpeg \
    openssh-server \
    openssh-client \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Verify Python version
RUN python3.12 --version

# CUDA toolkit and cuDNN already included in nvidia/cuda base image

# Configure SSH for root login
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd && \
    rm -f /etc/ssh/ssh_host_*

# Create virtual environment to avoid externally-managed-environment error
RUN python3.12 -m venv /opt/comfyui-env && \
    /opt/comfyui-env/bin/pip install --upgrade pip

# Install PyTorch with CUDA 12.8 (compatible with base image CUDA 12.8.0) - optimized for RTX 5090
RUN /opt/comfyui-env/bin/pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu128 && \
    /opt/comfyui-env/bin/pip cache purge

# Remove uv to force ComfyUI-Manager to use pip (uv doesn't respect --system-site-packages properly)
RUN pip uninstall -y uv 2>/dev/null || true && \
    rm -f /usr/local/bin/uv /usr/local/bin/uvx

# Install ComfyUI latest stable version
WORKDIR /opt/ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    /opt/comfyui-env/bin/pip install --no-cache-dir -r requirements.txt && \
    /opt/comfyui-env/bin/pip install --no-cache-dir GitPython opencv-python && \
    /opt/comfyui-env/bin/pip cache purge

# Install llama-cpp-python for GGUF support (CUDA 12.8 compatible with base image)
RUN /opt/comfyui-env/bin/pip install --upgrade --force-reinstall --no-cache-dir \
    https://github.com/JamePeng/llama-cpp-python/releases/download/v0.3.33-cu128-Basic-linux-20260315/llama_cpp_python-0.3.33+cu128.basic-cp312-cp312-linux_x86_64.whl && \
    /opt/comfyui-env/bin/pip cache purge

# Install ALL ComfyUI custom nodes from VastAI provisioning + RunpodDirect
RUN cd /opt/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/kijai/ComfyUI_essentials.git && \
    git clone https://github.com/huchukato/comfy-tagcomplete.git && \
    git clone https://github.com/huchukato/ComfyUI-QwenVL-Mod.git && \
    git clone https://github.com/huchukato/ComfyUI-RIFE-TensorRT-Auto.git && \
    git clone https://github.com/huchukato/ComfyUI-Upscaler-TensorRT-Auto.git && \
    git clone https://github.com/huchukato/ComfyUI-HuggingFace.git && \
    git clone https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    git clone https://github.com/MoonGoblinDev/Civicomfy.git && \
    git clone https://github.com/Koishi-Star/Euler-Smea-Dyn-Sampler.git && \
    git clone https://github.com/ltdrdata/was-node-suite-comfyui.git && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    git clone https://github.com/Smirnov75/ComfyUI-mxToolkit.git && \
    git clone https://github.com/princepainter/ComfyUI-PainterI2V.git && \
    git clone https://github.com/princepainter/ComfyUI-PainterLongVideo.git && \
    git clone https://github.com/ashtar1984/comfyui-find-perfect-resolution.git && \
    git clone https://github.com/huchukato/ComfyUI-Selectors.git && \
    git clone https://github.com/kijai/ComfyUI-MMAudio.git && \
    git clone https://github.com/GACLove/ComfyUI-VFI.git && \
    git clone https://github.com/stduhpf/ComfyUI-WanMoeKSampler.git && \
    git clone https://github.com/melMass/comfy_mtb.git

# Copy wildcards to Easy-Use (required for wildcard workflows)
RUN cp -r /opt/ComfyUI/custom_nodes/comfy-tagcomplete/wildcards/mbe /opt/ComfyUI/custom_nodes/ComfyUI-Easy-Use/wildcards || echo "Wildcards copy completed (or already exists)"

# Install requirements for all custom nodes
RUN bash -c 'cd /opt/ComfyUI/custom_nodes && for node_dir in */; do if [ -f "$node_dir/requirements.txt" ]; then echo "Installing requirements for $node_dir..." && /opt/comfyui-env/bin/pip install --no-cache-dir -r "$node_dir/requirements.txt" || echo "Failed to install requirements for $node_dir"; fi; done' && \
    /opt/comfyui-env/bin/pip cache purge

# Install additional essential dependencies
RUN /opt/comfyui-env/bin/pip install --no-cache-dir jupyter sageattention && \
    /opt/comfyui-env/bin/pip cache purge

# Clean up heavy Git files to save space (keep repo structure for updates)
RUN find /opt/ComfyUI/custom_nodes -name ".git" -type d -exec find {} -name "*.pack" -delete + || true && \
    find /opt/ComfyUI/custom_nodes -name ".git" -type d -exec find {} -name "pack-*.idx" -delete + || true && \
    find /opt/ComfyUI/custom_nodes -name ".git" -type d -exec find {} -name "objects" -type d -exec rm -rf {} + || true

# Create FileBrowser (RunPod method)
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# Create FileBrowser database and directories
RUN mkdir -p /filebrowser && \
    mkdir -p /filebrowser/database && \
    mkdir -p /filebrowser/files && \
    ln -sf /workspace/ComfyUI /filebrowser/files/ComfyUI && \
    echo '{"port": 8080, "baseURL": "", "address": "0.0.0.0", "log": "stdout", "database": "/filebrowser/database/filebrowser.db", "root": "/filebrowser/files", "noauth": true}' > /filebrowser/.config.json

# Create FileBrowser startup script
RUN echo '#!/bin/bash\n\
    echo "📁 Starting FileBrowser on port 8080"\n\
    echo "🌐 Access at: http://0.0.0.0:8080"\n\
    echo "👤 No authentication required"\n\
    echo ""\n\
    cd /filebrowser\n\
    filebrowser --config /filebrowser/.config.json\n\
    ' > /usr/local/bin/start-filebrowser.sh && chmod +x /usr/local/bin/start-filebrowser.sh

# Create Jupyter Lab startup script
RUN printf '%s\n' \
    '#!/bin/bash' \
    'echo "📓 Starting Jupyter Lab on port 8888"' \
    'echo "🌐 Access at: http://0.0.0.0:8888"' \
    'echo "🔑 No token required"' \
    'echo ""' \
    'cd /workspace/ComfyUI' \
    'echo "🔧 Starting Jupyter Lab with terminal support..."' \
    'nohup /opt/comfyui-env/bin/jupyter lab \' \
    '    --allow-root \' \
    '    --no-browser \' \
    '    --port=8888 \' \
    '    --ip=0.0.0.0 \' \
    '    --FileContentsManager.delete_to_trash=False \' \
    '    --FileContentsManager.preferred_dir=/workspace/ComfyUI \' \
    '    --ServerApp.root_dir=/workspace/ComfyUI \' \
    '    --ServerApp.terminado_settings='"'"'{"shell_command":["/bin/bash"]}'"'"' \' \
    '    --IdentityProvider.token="" \' \
    '    --ServerApp.allow_origin=* &> /jupyter.log &' \
    'echo "✅ Jupyter Lab started"' \
    'echo "🔍 Checking Jupyter Lab status..."' \
    'sleep 5' \
    'if pgrep -f "jupyter lab" > /dev/null; then' \
    '    echo "✅ Jupyter Lab started successfully"' \
    '    echo "📊 Jupyter Lab logs:"' \
    '    tail -10 /jupyter.log' \
    'else' \
    '    echo "❌ Jupyter Lab failed to start"' \
    '    echo "📊 Full error logs:"' \
    '    cat /jupyter.log' \
    '    echo "🔍 Checking what went wrong..."' \
    '    echo "🐍 Python version in virtual env:"' \
    '    /opt/comfyui-env/bin/python --version' \
    '    echo "📦 Jupyter Lab version in virtual env:"' \
    '    /opt/comfyui-env/bin/jupyter lab --version' \
    'fi' \
    > /usr/local/bin/start-jupyter.sh
RUN chmod +x /usr/local/bin/start-jupyter.sh

# Create user directory structure
RUN mkdir -p /opt/ComfyUI/user/default/workflows

# Create models directories
RUN mkdir -p /opt/ComfyUI/models/vae && \
    mkdir -p /opt/ComfyUI/models/upscale_models && \
    mkdir -p /opt/ComfyUI/models/text_encoders

# Clean up heavy Git files to save space (keep repo structure for updates)
RUN find /opt/ComfyUI/custom_nodes -name ".git" -type d -exec find {} -name "*.pack" -delete + || true && \
    find /opt/ComfyUI/custom_nodes -name ".git" -type d -exec find {} -name "pack-*.idx" -delete + || true && \
    find /opt/ComfyUI/custom_nodes -name ".git" -type d -exec find {} -name "objects" -type d -exec rm -rf {} + || true

# Aggressive cleanup to reduce image size
RUN rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && find /opt/ComfyUI -name "*.pyc" -delete \
    && find /opt/ComfyUI -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true \
    && /opt/comfyui-env/bin/pip cache purge

# Set ComfyUI arguments (optimized for WAN2.2 with SageAttention)
ENV COMFYUI_ARGS="--listen 0.0.0.0 --port 8188 --disable-auto-launch --enable-cors-header --fast fp16_accumulation --use-sage-attention --reserve-vram 2 --cuda-malloc --async-offload"

# Create startup script (RunPod style with dynamic workflow updates)
COPY start.sh /usr/local/bin/start-comfyui.sh
RUN chmod +x /usr/local/bin/start-comfyui.sh

# Set working directory
WORKDIR /workspace

# Expose ports
EXPOSE 8080 8188 8888 22

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://0.0.0.0:8188/system_stats || exit 1

# Start ComfyUI
CMD ["/usr/local/bin/start-comfyui.sh"]
