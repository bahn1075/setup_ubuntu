"""Verify real ROCm GPU execution; run with the ROCm PyTorch environment."""
import json

import torch


assert torch.version.hip, "ROCm PyTorch is required"
assert torch.cuda.is_available(), "No accessible ROCm GPU"
torch.backends.cuda.matmul.allow_tf32 = False
torch.manual_seed(42)
left = torch.randn(256, 256)
right = torch.randn(256, 256)
gpu_left = left.to("cuda")
gpu_right = right.to("cuda")
actual = gpu_left @ gpu_right
assert actual.device.type == "cuda", "Matrix multiplication did not run on the GPU"
torch.cuda.synchronize()
torch.testing.assert_close(actual.cpu(), left @ right, rtol=1e-4, atol=1e-4)
properties = torch.cuda.get_device_properties(0)
print(json.dumps({
    "torch": torch.__version__,
    "hip": torch.version.hip,
    "gpu": properties.name,
    "architecture": properties.gcnArchName,
    "vram_bytes": properties.total_memory,
    "device": str(actual.device),
    "matrix_shape": list(actual.shape),
    "cpu_result_matches": True,
    "status": "PASS",
}, indent=2))
