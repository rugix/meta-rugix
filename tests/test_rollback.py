"""Tests for rollback behavior after failed or uncommitted updates."""

import pytest

from rugix_testkit import RugixCtrl, VMHandle


@pytest.mark.slow
def test_rollback_without_commit(vm: VMHandle, rugix: RugixCtrl, bundle_url: str):
    """An uncommitted update should roll back to the original slot on reboot."""
    rugix.update_install(bundle_url, reboot="set")
    vm.reboot()

    rugix = RugixCtrl(vm)
    info = rugix.system_info()
    assert info.active_group == "b"
    assert info.default_group == "a"

    vm.reboot()

    rugix = RugixCtrl(vm)
    info = rugix.system_info()
    assert info.active_group == "a"
    assert info.default_group == "a"
