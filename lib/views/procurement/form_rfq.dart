import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class FormRFQ extends StatefulWidget {
  const FormRFQ({super.key});

  @override
  State<FormRFQ> createState() => _FormRFQState();
}

class _FormRFQState extends State<FormRFQ> {
  final _formKey = GlobalKey<FormState>();
  String? selectedVendor;
  final paymentTermsController = TextEditingController();
  final deliveryTermsController = TextEditingController();

  // Controllers untuk asset pertama
  final assetName1Controller = TextEditingController();
  final qty1Controller = TextEditingController();
  final estimatedCost1Controller = TextEditingController();

  // Controllers untuk asset kedua
  final assetName2Controller = TextEditingController();
  final qty2Controller = TextEditingController();
  final estimatedCost2Controller = TextEditingController();

  @override
  void dispose() {
    paymentTermsController.dispose();
    deliveryTermsController.dispose();
    assetName1Controller.dispose();
    qty1Controller.dispose();
    estimatedCost1Controller.dispose();
    assetName2Controller.dispose();
    qty2Controller.dispose();
    estimatedCost2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: const CustomAppBar(),
        toolbarHeight: 82,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF213268), width: 0.5),
        ),
        child: Stack(
          children: [
            // Form scrollable content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 70 // Beri ruang untuk tombol di bawah
                    ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Form sebelah kiri
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'RFQ FORM',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF213268),
                            ),
                          ),
                        ),
                      ),

                      // Vendor dropdown
                      const Text(
                        'Vendor',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            hint: const Text(
                              'Select Vendor',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                            value: selectedVendor,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF213268),
                            ),
                            items: <String>['Vendor A', 'Vendor B', 'Vendor C']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedVendor = newValue;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Payment Terms
                      const Text(
                        'Payment Terms',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD9D9D9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: paymentTermsController,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter Payment Terms',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Delivery Terms
                      const Text(
                        'Delivery Terms',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD9D9D9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: deliveryTermsController,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter Delivery Terms',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // List Asset
                      const Text(
                        'List Asset',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Asset 1
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF213268)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Asset Name
                              const Text(
                                'Asset Name 1',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: assetName1Controller,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Asset Name 1',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Qty
                              const Text(
                                'Qty',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: qty1Controller,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Qty',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Estimated Cost
                              const Text(
                                'Estimated Cost',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: estimatedCost1Controller,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Estimated Cost',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Asset 2
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF213268)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Asset Name
                              const Text(
                                'Asset Name 2',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: assetName2Controller,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Asset Name 2',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Qty
                              const Text(
                                'Qty',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: qty2Controller,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Qty',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Estimated Cost
                              const Text(
                                'Estimated Cost',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFCCCCCC)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: estimatedCost2Controller,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Estimated Cost',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60), // Ruang untuk tombol
                    ],
                  ),
                ),
              ),
            ),

            // Submit Button (posisi tetap di bawah)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, -1),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Kumpulkan data dari form
                      Map<String, dynamic> formData = {
                        'vendorName': selectedVendor ?? "Vendor Name",
                        'paymentTerms': paymentTermsController.text,
                        'deliveryTerms': deliveryTermsController.text,
                        'assetName1': assetName1Controller.text,
                        'qty1': qty1Controller.text,
                        'estimatedCost1': estimatedCost1Controller.text,
                        'assetName2': assetName2Controller.text,
                        'qty2': qty2Controller.text,
                        'estimatedCost2': estimatedCost2Controller.text,
                      };

                      // Kembali ke procurement_screen dengan data
                      Navigator.pop(context, formData);
                    } else {
                      // Jika validasi gagal, hanya tampilkan pesan
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Harap isi semua field yang diperlukan')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF213268),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
