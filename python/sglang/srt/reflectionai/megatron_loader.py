"""Megatron loader stub for SGLang."""


from sglang.srt.configs.device_config import DeviceConfig
from sglang.srt.configs.model_config import ModelConfig
from sglang.srt.model_loader.loader import BaseModelLoader
import torch
import torch.nn as nn


class MegatronModelLoader(BaseModelLoader):
  """Model loader that uses Megatron checkpoint conversion system for weight mapping."""



  def load_model(
    self,
    *,
    model_config: ModelConfig,
    device_config: DeviceConfig,
  ) -> nn.Module:
    raise NotImplementedError("This class is a stub and must be patched from olympus!")

  def load_weights(
    self,
    model_config: ModelConfig,
    model: nn.Module,
    target_device: torch.device,
  ) -> None:
    
    raise NotImplementedError("This class is a stub and must be patched from olympus!")