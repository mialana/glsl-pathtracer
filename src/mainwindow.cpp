#include "mainwindow.h"
#include <ui_mainwindow.h>
#include "cameracontrolshelp.h"

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    ui->mygl->setFocus();

    connect(ui->actionQuit, &QAction::triggered, this, &MainWindow::slot_actionQuit_triggered);
    connect(ui->actionCamera_Controls,
            &QAction::triggered,
            this,
            &MainWindow::slot_actionCamera_Controls_triggered);
    connect(ui->actionLoad_Environment_Map_Ctrl_O,
            &QAction::triggered,
            this,
            &MainWindow::slot_actionLoad_Environment_Map_Ctrl_O_triggered);
    connect(ui->actionLoad_JSON_Scene,
            &QAction::triggered,
            this,
            &MainWindow::slot_actionLoad_JSON_Scene_triggered);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::slot_actionQuit_triggered()
{
    close();
    QApplication::exit();
}

void MainWindow::slot_actionCamera_Controls_triggered()
{
    CameraControlsHelp* c = new CameraControlsHelp();
    c->show();
}

void MainWindow::slot_actionLoad_Environment_Map_Ctrl_O_triggered()
{
    ui->mygl->loadEnvMap();
}

void MainWindow::slot_actionLoad_JSON_Scene_triggered()
{
    ui->mygl->loadJSON();
}
