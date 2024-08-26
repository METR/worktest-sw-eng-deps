ARG PYTHON_VERSION=3.11.9

FROM python:${PYTHON_VERSION}-bookworm
RUN useradd -m agent

ARG CUDA_DISTRO=ubuntu2204
ARG CUDA_VERSION=12.4

RUN CUDA_REPO="https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_DISTRO}/x86_64" \
 && CUDA_GPG_KEY=/usr/share/keyrings/nvidia-cuda.gpg \
 && wget -O- "${CUDA_REPO}/3bf863cc.pub" | gpg --dearmor > "${CUDA_GPG_KEY}" \
 && echo "deb [signed-by=${CUDA_GPG_KEY} arch=amd64] ${CUDA_REPO}/ /" > /etc/apt/sources.list.d/nvidia-cuda.list \
 && apt-get update -y \
 && apt-get install -yq --no-install-recommends \
    cuda-libraries-${CUDA_VERSION} \
    nvcc-${CUDA_VERSION} \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_VERSION}/lib64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

RUN pip install --upgrade pip setuptools wheel \
 && pip install cmake packaging torch \
 && rm -rf /root/.cache/pip

WORKDIR /home/agent/solution
ARG LLM_FOUNDRY_VERSION=77f9ab1843ded0c1a2741487ac28ff7669dfea88
RUN git clone https://github.com/mosaicml/llm-foundry.git . \
 && git checkout ${LLM_FOUNDRY_VERSION} \
 && pip install --no-cache-dir -e '.[gpu]' \
 && chown -R agent:agent .

USER agent
