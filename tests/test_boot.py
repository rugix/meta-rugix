"""Tests for initial boot and bootstrapping."""

from rugix_testkit import RugixCtrl, VMHandle


def test_boot_and_bootstrapping(rugix: RugixCtrl):
    """Verify that the first boot performs bootstrapping and reaches a healthy state."""
    info = rugix.system_info()
    assert info.active_group == "a"
    assert info.default_group == "a"


def test_both_slots_exist(rugix: RugixCtrl):
    """Verify both system slots are present after bootstrapping."""
    info = rugix.system_info()
    assert "system-a" in info.slots
    assert "system-b" in info.slots


def test_ssh_and_basic_system(vm: VMHandle):
    """Verify basic system health over SSH."""
    result = vm.run(["uname", "-s"], hide=True)
    assert result.stdout.strip() == "Linux"

    result = vm.run(["systemctl", "is-system-running"], check=False, hide=True)
    assert result.stdout.strip() in ("starting", "running", "degraded")
