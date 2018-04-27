`timescale 1ns / 1ps

module model_uart(/*AUTOARG*/
   // Outputs
   TX,
   // Inputs
   RX
   );

   output TX;
   input  RX;

   parameter baud    = 115200;
   parameter bittime = 1000000000/baud;
   parameter name    = "UART0";
   
   reg [7:0] rxData;
   event     evBit;
   event     evByte;
   event     evTxBit;
   event     evTxByte;
   reg       TX;

   //idea, let's make a buffer, and flushes when we see a carriage return
   reg [39:0] buff = 0; //let's initially set it to zero, let's set buff to 40 bits, bc we only want to output 4 bytes + 1 byte for the newline

   initial
     begin
        TX = 1'b1;
     end
   
   always @ (negedge RX)
     begin
        rxData[7:0] = 8'h0;
        #(0.5*bittime);
        repeat (8)
          begin
             #bittime ->evBit; //need to surpress per byte output
             //rxData[7:0] = {rxData[6:0],RX};
             rxData[7:0] = {RX,rxData[7:1]};
          end
        ->evByte; //each byte is 8 bits, let's wait until we get 4 bytes first or 16 bits and then output
          //let's left shift to make room
          buff = buff << 8; //left shift by 8 bits to make room for the next byte, shift by 8 bc 8 bits per byte
          buff = {buff, rxData}; //concatenates buff with rxData

          if ( rxData == 4'h0D) //we only output when we see a carriage return, then we reset buffer to 0, carriage return in verilog is 0x0D
          begin
              $display("Nicer UART output: %s", buff);
              buff = 0; //reset buffer to 0
          end


        //$display ("%d %s Received byte %02x (%s)", $stime, name, rxData, rxData);
     end

   task tskRxData;
      output [7:0] data;
      begin
         @(evByte);
         data = rxData;
      end
   endtask // for
      
   task tskTxData;
      input [7:0] data;
      reg [9:0]   tmp;
      integer     i;
      begin
         tmp = {1'b1, data[7:0], 1'b0};
         for (i=0;i<10;i=i+1)
           begin
              TX = tmp[i];
              #bittime;
              ->evTxBit;
           end
         ->evTxByte;
      end
   endtask // tskTxData
   
endmodule // model_uart
