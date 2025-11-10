use std::fs;
use std::path::PathBuf;
use dicom::object::open_file; //, FileDicomObject}; //, Result};
use dicom::core::Tag;
use fltk::{app, input::Input, button::Button, frame::Frame, prelude::*, window::Window, group, dialog};
use std::process::Command;
use std::io::{self, Write};

use clap::Parser;


fn find_dcms(session_dir: &str) -> Result<(Option<DCM>, Option<DCM>, Option<DCM>), Box<dyn std::error::Error>> {
    // these are the 3 acq. we care about
    let mut epi : Option<DCM> = None;
    let mut mag : Option<DCM> = None;
    let mut phase : Option<DCM> = None;

    // look through all session dir for them
    for entry in fs::read_dir(session_dir)? {
        let acq = entry?.path();
        if acq.is_dir() {
            for dcm in fs::read_dir(acq)? {
                let dcm = dcm?;
                let path = dcm.path();
                // classify only the first dicom in folder
                if dcm.file_type()?.is_file() {
                    let pfname = path.file_name().ok_or("no filename?");
                    let Some(fname) = pfname?.to_str() else { todo!()};
                    // skip non-dicom files. fragile by name MR* *.dcm *.IMA
                    if ! ( fname.starts_with("MR") || fname.ends_with("dcm") || fname.ends_with("DCM")  || fname.ends_with("IMA")) { continue }

                    println!("found file {}", path.display());
                    let dcm = classify(&path)?;
                    if dcm.class == ScanFor::mag && mag.is_none() {
                        mag = Some(dcm)
                    } else if dcm.class == ScanFor::phase && phase.is_none() {
                        phase= Some(dcm)
                    } else if dcm.class == ScanFor::epi && epi.is_none() {
                        epi = Some(dcm)
                    }
                    // only needed to inspect first
                    break
                }
            }
        }
    }
    // return order how we expect to have scanned. but is otherwise arbitrary
    Ok((epi,mag,phase))
}

#[derive(PartialEq)]
enum ScanFor {epi, phase, mag, ignore}

struct DCM {
    path: String,
    seqnum: String,
    pname: String,
    aname: String,
    phmag: String,
    class: ScanFor
}
//fn tag(obj: &FileDicomObject, GG: u16, EE: u16) -> Result<String, Box<dyn std::error::Error>>{
//    Ok(obj.element(Tag(GG,EE))?.to_str()?.to_string())
//}
//  getting types for above is painful. ugly macro works just fine
// to_str? to_string is ugly
macro_rules! tag { ($o:expr, $GG:expr, $EE:expr) => {$o.element(Tag($GG,$EE))?.to_str()?.to_string()} }

fn classify(dcm_fname: &PathBuf) -> Result<DCM, Box<dyn std::error::Error>> {
    let obj = open_file(dcm_fname)?;
    // TODO: use elemnt_from_name. have actual codes from dicom_hdr/dcmdump
    let mut d = DCM {path: dcm_fname.parent().expect("path has parent").display().to_string(),
                 seqnum: tag!(obj,0x0020,0x0011),
                 pname:  tag!(obj,0x0018,0x0024),
                 aname:  tag!(obj,0x0018,0x1030),
                 phmag:  tag!(obj,0x0051,0x1016),
                 class: ScanFor::ignore};

    if d.aname.contains("GRE") && d.phmag.contains("P/ND") {
        d.class = ScanFor::phase
    } else if d.aname.contains("GRE") && d.phmag.contains("M/ND") {
        d.class = ScanFor::mag
    } else if d.pname.contains("epfid2d1") && d.aname.contains("incang") {
        d.class = ScanFor::epi
    }
    println!("{}\n\tseqnum={} pname={} aname={}, phmag={}", d.path, d.seqnum, d.pname, d.aname, d.phmag);
    Ok(d)
}

fn get_dir(mesg: &str, default: &str) -> String {
    let start_in = "./"; // TODO: test if default is dir. use parent
    let dlg = dialog::dir_chooser(mesg, start_in, true);
    match dlg {
        Some(path) => path,
        None => default.to_string(),
    }
}
fn get_file(mesg: &str, default: &str) -> String {
    let dlg = dialog::file_chooser(mesg, ".*", ".", true);
    match dlg {
        Some(path) => path,
        None => default.to_string(),
    }
}

fn copy_ssh(con: &str, id: &str, src: &str, dest: &str) -> std::process::Output {
    // scp -rpi %ID_FILE% %* %SERVER%:%upload_area%
    Command::new("echo")
        .arg("scp").arg("-rpi").arg(id).arg(con)
        .output().expect("scp executed")
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Session directory with DICOM folder children
    #[arg(short, long, default_value_t = String::from("./"))]
    sessiondir: String,
}
fn main() {
    let args = Args::parse();
    let app = app::App::default(); //.with_scheme(app::Scheme::Gtk);
    let mut win = Window::default().with_size(800, 300);
    let mut flex_row = group::Flex::new(0, 0, 800, 300, None);
    flex_row.set_type(group::FlexType::Row);
    let mut flex_col = group::Flex::new(0, 0, 100, 100, None);
    flex_col.set_type(group::FlexType::Column);
    let mut mtiltepi = Button::default().with_label("<EPI>");
    let mut mag  = Button::default().with_label("<Mag>");
    let mut phase  = Button::default().with_label("<Phase>");
    let mut angle  = Button::default().with_label("angle.txt");
    let mut upload  = Button::default().with_label("Run!");
    let mut frame = Frame::default().with_label("x");

    let mut sshrow = group::Flex::new(0, 0, 400, 100, None);
    sshrow.set_type(group::FlexType::Row);
    let mut host = Input::default();
    host.set_value("moon@");
    let mut sshid = Input::default();
    sshid.set_value("gyrus2");
    sshrow.end();

    flex_col.end();

    let mut log = fltk::terminal::Terminal::default();
    flex_row.end();

   // -- show
    win.resizable(&flex_row);
    win.end();
    win.show();

    // -- callbacks
    mtiltepi.set_callback(move |s| s.set_label(&get_dir("MultiTilt EPI DICOM Folder", &s.label())));
    mag.set_callback(move |s| s.set_label(&get_dir("Mag GRE DICOM Folder", &s.label())));
    phase.set_callback(move |s| s.set_label(&get_dir("Phase GRE EPI DICOM Folder", &s.label())));
    angle.set_callback(move |s| s.set_label(&get_file("Angle Order text file", &s.label())));
    upload.set_callback({
        move |_| {
            let host =&host.value();
            let id = &sshid.value();
            let cp_out = String::from_utf8(copy_ssh(host,id,"x","y").stdout);
            match &cp_out {
                Ok(val) => log.append(&val),
                Err(_) => todo!()}
            let run_out = String::from_utf8(copy_ssh(host,id,"x","y").stdout);
            match &run_out {
                Ok(val) => log.append(&val),
                Err(_) => todo!()}}
    });


    // set labels
    if let dcm_locs = find_dcms(&args.sessiondir).unwrap() { // epi, mag, phase
        if ! dcm_locs.0.is_none() {
            mtiltepi.set_label(&dcm_locs.0.unwrap().path)
        }
        if ! dcm_locs.1.is_none() {
            mag.set_label(&dcm_locs.1.unwrap().path)
        }
        if ! dcm_locs.2.is_none() {
            phase.set_label(&dcm_locs.2.unwrap().path)
        }
    }

    frame.set_label("...");
    //log.append("blah\nblah\nblah");
    app.run().unwrap();
}
