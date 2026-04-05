"""Tests for the A/B system update workflow."""

import pytest

from rugix_testkit import RugixCtrl, VMHandle


@pytest.mark.slow
def test_update_and_reboot(vm: VMHandle, rugix: RugixCtrl, bundle_url: str):
    """Install an update, reboot into the spare slot, and verify."""
    assert rugix.system_info().active_group == "a"

    rugix.update_install(bundle_url, reboot="set")
    vm.reboot()

    rugix = RugixCtrl(vm)
    assert rugix.system_info().active_group == "b"


@pytest.mark.slow
def test_update_commit(vm: VMHandle, rugix: RugixCtrl, bundle_url: str):
    """Install, reboot, commit, and verify the new default."""
    rugix.update_install(bundle_url, reboot="set")
    vm.reboot()

    rugix = RugixCtrl(vm)
    info = rugix.system_info()
    assert info.active_group == "b"
    assert info.default_group == "a"

    rugix.system_commit()
    info = rugix.system_info()
    assert info.default_group == "b"
    assert info.active_group == "b"

    vm.reboot()

    rugix = RugixCtrl(vm)
    info = rugix.system_info()
    assert info.active_group == "b"
    assert info.default_group == "b"
