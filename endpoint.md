{{url}}/asset-opnames

{
    "room_id":3
}

response

{
    "success": true,
    "message": "Pemeriksaan aset berhasil dibuat",
    "data": {
        "opname_id": 40,
        "opname_code": "OPN25070025",
        "room_id": 3,
        "room_name": "ICU Sterilisasi A",
        "conducted_by": 1,
        "conductor_name": "User 1234",
        "total_assets": 0,
        "scanned_assets": 0,
        "created_at": "2025-07-28T03:36:58.000Z",
        "updated_at": "2025-07-28T03:36:58.000Z"
    }
}


{{url}}/assets/qr/:assetCode

response

{
    "success": true,
    "message": "Aset berhasil diambil",
    "data": {
        "asset_id": 9,
        "asset_code": "MD-LSEQ-250718-0008-0001",
        "asset_master_id": 9,
        "asset_master_name": "CT Scanner",
        "asset_master": {
            "asset_master_code": "MD-LSEQ-250718-0008",
            "reference_image_path": "/images/placeholder.png",
            "asset_name": "CT Scanner",
            "description": "Alat pencitraan yang menggunakan sinar-X dan komputer untuk membuat gambar detail tubuh",
            "subcategory_id": 5,
            "subcategory_name": "Life Support Equipment",
            "is_depreciable": true,
            "needs_calibration": true,
            "asset_type": "medical"
        },
        "serial_number": "CT00000009",
        "model": "CT-M540I",
        "purchase_date": "2023-05-31",
        "purchase_cost": "4040463442.00",
        "warranty_end_date": "2025-05-31",
        "brand_id": 61,
        "brand_name": "Arjo",
        "user_id": 8,
        "employee_number": "2002",
        "employee_name": "User 2002",
        "current_status": "lost",
        "condition": "good",
        "room_id": 58,
        "room_name": "NICU Konsultasi",
        "building_name": "Gedung Perawatan Intensif",
        "floor_number": "4",
        "qr_code": "/qrcodes/qr_MD-LSEQ-250718-0008-0001.png",
        "created_at": "2025-07-18T03:56:48.000Z",
        "updated_at": "2025-07-25T01:29:12.000Z",
        "depreciation": {
            "id": 2,
            "depreciation_method": "Straight Line",
            "acquisition_cost": 4040463442,
            "salvage_value": 404046344,
            "asset_life_months": 120,
            "date_acquired": "2023-05-31"
        }
    }
}

{{url}}/asset-opname-details

{
    "opname_id":20,
    "actual_location_id":1,
    "asset_code":"MD-ANEQ-250718-0024-0001",
    "condition":"damaged",//good or damaged
    "notes":"dalam keadaan baik"//optional
}

response

{
    "success": true,
    "message": "Detail pemeriksaan aset berhasil dibuat",
    "data": [
        {
            "detail_id": 12,
            "asset_id": 25,
            "asset_code": "MD-ANEQ-250718-0024-0001",
            "asset_name": "Spirometer",
            "brand_name": "Cerner",
            "model": "SPI-M616Y",
            "serial_number": "SPI00000025",
            "pic": "User 1237",
            "asset_type": "medical",
            "category": "Anesthesia Equipment",
            "reference_image_path": "/images/placeholder.png",
            "scan_date": "2025-07-28T03:42:37.000Z",
            "scan_status": "misplaced",
            "condition": "damaged",
            "actual_location_id": 1,
            "actual_location_name": "Ruang MRI B | G | Blok ICU F",
            "expected_location_id": 101,
            "expected_location_name": "OK Perawat C | 6 | Gedung Radiologi",
            "scanned_by": 1,
            "scanner_name": "User 1234",
            "notes": "dalam keadaan baik",
            "created_at": "2025-07-18T04:21:18.000Z",
            "updated_at": "2025-07-28T03:42:37.000Z"
        },
        {
            "detail_id": 11,
            "asset_id": 81,
            "asset_code": "MD-EMEQ-250718-0080-0001",
            "asset_name": "PCR Machine",
            "brand_name": "Linet",
            "model": "PCR-M691C",
            "serial_number": "PCR00000081",
            "pic": "daytt",
            "asset_type": "medical",
            "category": "Emergency Equipment",
            "reference_image_path": "/images/placeholder.png",
            "scan_date": "2025-07-18T04:20:45.000Z",
            "scan_status": "misplaced",
            "condition": "damaged",
            "actual_location_id": 1,
            "actual_location_name": "Ruang MRI B | G | Blok ICU F",
            "expected_location_id": 143,
            "expected_location_name": "NICU Pemeriksaan 3 | 3 | Gedung Administrasi",
            "scanned_by": 181,
            "scanner_name": "daytt",
            "notes": "dalam keadaan baik",
            "created_at": "2025-07-18T04:20:45.000Z",
            "updated_at": "2025-07-18T04:20:45.000Z"
        }
    ]
}


{{url}}/asset-opname-details/3/notes

{
    "notes":"ditemukan di ruangan x"
}

response

{
    "success": true,
    "message": "Catatan detail pemeriksaan aset berhasil diperbarui",
    "data": {
        "detail_id": 3,
        "asset_id": 50,
        "asset_code": "NMD-REAI-250718-0049-0001",
        "asset_name": "Emergency Light",
        "brand_name": "Getinge",
        "model": "EME-N873X",
        "serial_number": "EME00000050",
        "pic": "User 2003",
        "asset_type": "non_medical",
        "category": "Rehabilitation Aids",
        "reference_image_path": "/images/placeholder.png",
        "scan_date": "2023-02-07T06:33:23.000Z",
        "scan_status": "found",
        "condition": "good",
        "actual_location_id": 15,
        "actual_location_name": "Poli Fisioterapi 3 | 4 | Gedung Perawatan Anak",
        "expected_location_id": 15,
        "expected_location_name": "Poli Fisioterapi 3 | 4 | Gedung Perawatan Anak",
        "scanned_by": 2,
        "scanner_name": "User 1235",
        "notes": "ditemukan di ruangan x",
        "created_at": "2023-02-07T06:33:23.000Z",
        "updated_at": "2025-07-28T03:37:30.000Z"
    }
}

{{url}}/asset-opnames/16/complete

response

{
    "success": true,
    "message": "Pemindaian pemeriksaan aset berhasil diselesaikan",
    "data": {
        "opname_id": 16,
        "opname_code": "OPN25070001",
        "room_id": 3,
        "room_name": "ICU Sterilisasi A",
        "conducted_by": 181,
        "conductor_name": "daytt",
        "total_assets": 0,
        "scanned_assets": 0,
        "created_at": "2025-07-18T04:00:01.000Z",
        "updated_at": "2025-07-28T03:37:45.000Z"
    }
}

{{url}}/asset-opname-details/opname/17

{
    "success": true,
    "message": "Detail pemeriksaan aset berhasil diambil",
    "data": {
        "details": [
            {
                "detail_id": 8,
                "asset_id": 81,
                "asset_code": "MD-EMEQ-250718-0080-0001",
                "asset_name": "PCR Machine",
                "brand_name": "Linet",
                "model": "PCR-M691C",
                "serial_number": "PCR00000081",
                "pic": "daytt",
                "asset_type": "medical",
                "category": "Emergency Equipment",
                "reference_image_path": "/images/placeholder.png",
                "scan_date": "2025-07-18T04:20:37.000Z",
                "scan_status": "misplaced",
                "condition": "damaged",
                "actual_location_id": 1,
                "actual_location_name": "Ruang MRI B | G | Blok ICU F",
                "expected_location_id": 143,
                "expected_location_name": "NICU Pemeriksaan 3 | 3 | Gedung Administrasi",
                "scanned_by": 181,
                "scanner_name": "daytt",
                "notes": "dalam keadaan baik",
                "created_at": "2025-07-18T04:09:50.000Z",
                "updated_at": "2025-07-18T04:20:37.000Z"
            },
            {
                "detail_id": 10,
                "asset_id": 2,
                "asset_code": "NMD-COHA-250718-0001-0001",
                "asset_name": "Desktop Computer",
                "brand_name": "Abbott",
                "model": "DES-N449B",
                "serial_number": "DES00000002",
                "pic": "User 1234",
                "asset_type": "non_medical",
                "category": "Computer Hardware",
                "reference_image_path": "/images/placeholder.png",
                "scan_date": "2025-07-18T04:17:39.000Z",
                "scan_status": "misplaced",
                "condition": "good",
                "actual_location_id": 1,
                "actual_location_name": "Ruang MRI B | G | Blok ICU F",
                "expected_location_id": 144,
                "expected_location_name": "ICU Perawat 3 | 1 | Gedung Poli Spesialis",
                "scanned_by": 1,
                "scanner_name": "User 1234",
                "notes": "dalam keadaan baik",
                "created_at": "2025-07-18T04:17:39.000Z",
                "updated_at": "2025-07-18T04:17:39.000Z"
            },
            {
                "detail_id": 9,
                "asset_id": 1,
                "asset_code": "MD-DIEQ-250718-0000-0001",
                "asset_name": "Patient Monitor",
                "brand_name": "3M Healthcare",
                "model": "PAT-M538A",
                "serial_number": "PAT00000001",
                "pic": "daytt",
                "asset_type": "medical",
                "category": "Diagnostic Equipment",
                "reference_image_path": "/images/placeholder.png",
                "scan_date": "2025-07-18T04:17:22.000Z",
                "scan_status": "misplaced",
                "condition": "good",
                "actual_location_id": 1,
                "actual_location_name": "Ruang MRI B | G | Blok ICU F",
                "expected_location_id": 143,
                "expected_location_name": "NICU Pemeriksaan 3 | 3 | Gedung Administrasi",
                "scanned_by": 1,
                "scanner_name": "User 1234",
                "notes": "dalam keadaan baik",
                "created_at": "2025-07-18T04:17:22.000Z",
                "updated_at": "2025-07-18T04:17:22.000Z"
            }
        ],
        "pagination": {
            "total_items": 3,
            "total_pages": 1,
            "current_page": 1,
            "limit": 10,
            "has_next": false,
            "has_prev": false
        },
        "summary": {
            "total_assets": 0,
            "scanned_assets": 3,
            "found_assets": 0,
            "missing_assets": 0,
            "misplaced_assets": 3
        },
        "room_info": {
            "room_id": 3,
            "room_name": "ICU Sterilisasi A",
            "floor": "4",
            "building": "Gedung Laundry F"
        },
        "opname_info": {
            "opname_id": 17,
            "opname_code": "OPN25070002",
            "opname_created_at": "2025-07-18T04:05:29.000Z"
        }
    }
}