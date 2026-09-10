"""Unit tests for doctor diagnostics."""

from locationctl.diagnostics.doctor import Doctor


def test_doctor_scan():
    report = Doctor.run_checks()
    assert report.platform != ""
    assert report.python_version != ""
    assert len(report.items) >= 3

    # Ensure all items have valid status
    for item in report.items:
        assert item.status in ("OK", "WARN", "FAIL", "INFO")
        assert len(item.name) > 0
