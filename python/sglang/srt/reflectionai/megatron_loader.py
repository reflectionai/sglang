"""Megatron loader stub for SGLang."""

from abc import ABC, abstractmethod
from typing import Any

class MegatronModelLoaderBase(ABC):
  @abstractmethod
  def load_model(
    self,
    *,
    model_config: Any,
    device_config: Any,
  ) -> Any:
    pass
  @abstractmethod
  def load_weights(
    self,
    model_config: Any,
    model: Any,
    target_device: Any,
  ) -> None:
    pass